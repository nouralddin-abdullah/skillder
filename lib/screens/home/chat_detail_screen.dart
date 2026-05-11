import 'dart:async';

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/chat_models.dart';
import '../../models/dummy_user.dart';
import '../../services/auth_storage.dart';
import '../../services/chat_outbox_service.dart';
import '../../services/chat_repository.dart';
import '../../services/chat_service.dart';
import '../../services/chat_socket_service.dart';
import '../../services/chat_sync_service.dart';
import '../../services/matching_service.dart';
import '../../theme/app_colors.dart';
import '../chat/media_preview_screen.dart';
import '../../widgets/chat/image_viewer.dart';
import '../../widgets/chat/video_viewer.dart';
import '../../widgets/swipe/profile_bottom_sheet.dart';

/// Number of older messages to load per pagination request from the server.
const int _historyPageSize = 50;

/// Distance from the top of the scroll view that triggers older-message
/// pagination from the server.
const double _paginationTriggerOffset = 200;

class ChatDetailScreen extends StatefulWidget {
  final ChatSummary chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  /// Messages stored OLDEST → NEWEST. Mirrored from the local DB stream.
  List<MessageEntity> _messages = const [];

  /// In-flight reply target. Null when not replying.
  MessageEntity? _replyingTo;

  /// In-flight edit target. Null when sending fresh messages.
  MessageEntity? _editingMessage;
  bool _editSubmitting = false;

  /// Resolved on init from [AuthStorage].
  String? _currentUserId;

  /// Mutable so unmatch / re-match can flip it locally even before sync.
  late ChatSummary _chat = widget.chat;

  ChatRepository? _repo;
  ChatOutboxService? _outbox;
  ChatSyncService? _sync;
  ChatSocketService? _socket;

  StreamSubscription<List<MessageEntity>>? _messagesSub;
  StreamSubscription<ChatSummary?>? _chatSub;
  StreamSubscription<TypingNotification>? _typingSub;

  /// True while the other party is typing. Auto-clears 5s after the last
  /// typing.start with no follow-up event (in case typing.stop is missed).
  bool _otherIsTyping = false;
  Timer? _typingClearTimer;

  /// Throttle our own typing.start emissions to once every 3s while the
  /// user is actively typing. Stops are sent immediately on send / blur.
  DateTime? _lastTypingStartEmittedAt;
  bool _typingActive = false;
  Timer? _typingStopTimer;

  bool _initialBackfilled = false;
  bool _backfillFailed = false;
  bool _loadingOlder = false;
  bool _hasMoreOnServer = true;

  /// The id of the latest non-mine message we've POSTed `/read` for.
  String? _lastReadServerId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _messagesSub?.cancel();
    _chatSub?.cancel();
    _typingSub?.cancel();
    _typingClearTimer?.cancel();
    _typingStopTimer?.cancel();
    _emitTypingStop();
    _sync?.focusedChats.remove(_chat.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────── Bootstrap ────────────────────────────────

  Future<void> _bootstrap() async {
    _currentUserId = await AuthStorage.getUserId();
    final repo = await ChatRepositoryHolder.instance();
    final outbox = await ChatOutboxServiceHolder.instance();
    final sync = await ChatSyncServiceHolder.instance();
    final socket = await ChatSocketServiceHolder.instance();
    if (!mounted) return;

    setState(() {
      _repo = repo;
      _outbox = outbox;
      _sync = sync;
      _socket = socket;
    });

    sync.focusedChats.add(_chat.chatId);
    sync.currentUserId ??= _currentUserId;

    // Make sure the live channel is open while a chat is on screen — if
    // the user came back from background, this guarantees we reconnect.
    unawaited(socket.connect());

    _typingSub = socket.typingStream.listen(_onTypingNotification);

    // Make sure the cached chat row matches what was passed in (the parent
    // route may carry an older snapshot).
    await repo.upsertChat(widget.chat);

    _messagesSub = repo.watchMessages(_chat.chatId).listen(_onMessagesChanged);
    _chatSub = repo.watchChat(_chat.chatId).listen(_onChatChanged);

    // First-render path: we already have local rows for older opens. The
    // backfill below freshens them. For brand-new chats it's the first load.
    await _backfillFromServer();

    // Drain the outbox in case there are sends queued from a prior session.
    unawaited(outbox.drain());
  }

  Future<void> _backfillFromServer() async {
    try {
      final batch = await ChatService.getHistory(
        _chat.chatId,
        limit: _historyPageSize,
      );
      if (!mounted) return;
      await _repo?.upsertMessages(batch);
      _hasMoreOnServer = batch.length >= _historyPageSize;
      setState(() => _initialBackfilled = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialBackfilled = true;
        _backfillFailed = true;
      });
    }
  }

  void _onMessagesChanged(List<MessageEntity> updated) {
    setState(() => _messages = updated);
    // No scroll-to-bottom hack needed — the ListView is `reverse: true`, so
    // newest messages are anchored to the visual bottom by default and a
    // brand-new message appears there without any post-frame jump.
    _markLatestAsRead();
  }

  void _onChatChanged(ChatSummary? updated) {
    if (updated == null || !mounted) return;
    setState(() => _chat = updated);
    if (updated.removedByMe && _replyingTo != null) {
      setState(() => _replyingTo = null);
    }
  }

  // ─────────────────────────── Pagination ───────────────────────────────

  Future<void> _loadOlderFromServer() async {
    if (_loadingOlder || !_hasMoreOnServer) return;
    final oldest = _firstServerMessage();
    if (oldest == null) return;

    setState(() => _loadingOlder = true);
    try {
      final batch = await ChatService.getHistory(
        _chat.chatId,
        beforeMessageId: oldest.id,
        limit: _historyPageSize,
      );
      if (!mounted) return;
      await _repo?.upsertMessages(batch);
      _hasMoreOnServer = batch.length >= _historyPageSize;
      // Reversed ListView keeps the user's scroll position stable when
      // older items are appended at the END of the data — no jump-to-offset
      // dance needed.
    } catch (_) {
      // Silent — user can retry by scrolling again.
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  MessageEntity? _firstServerMessage() {
    for (final m in _messages) {
      if (m.id != null) return m;
    }
    return null;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Reversed list: max-extent corresponds to scrolled-up-to-oldest. Trigger
    // pagination when the user is approaching the top.
    if ((pos.maxScrollExtent - pos.pixels) < _paginationTriggerOffset &&
        !_loadingOlder &&
        _hasMoreOnServer &&
        _initialBackfilled) {
      _loadOlderFromServer();
    }
  }

  // ─────────────────────────── Read receipt ─────────────────────────────

  Future<void> _markLatestAsRead() async {
    if (_chat.removedByMe) return;
    MessageEntity? lastFromOther;
    for (final m in _messages.reversed) {
      if (m.id != null && !_isMine(m) && !m.isSystem && !m.isDeleted) {
        lastFromOther = m;
        break;
      }
    }
    if (lastFromOther?.id == null) return;
    final id = lastFromOther!.id!;
    if (id == _lastReadServerId) return;
    _lastReadServerId = id;

    // Local optimistic — clear the unread badge immediately.
    final repo = _repo;
    if (repo != null) {
      await repo.resetUnread(
        chatId: _chat.chatId,
        lastReadAt: DateTime.now().toUtc(),
      );
    }

    try {
      await ChatService.markRead(
        chatId: _chat.chatId,
        upToMessageId: id,
      );
    } catch (_) {
      // Best-effort — sync delta will pick up the canonical state.
    }
  }

  // ─────────────────────────── Typing ──────────────────────────────────

  void _onTypingNotification(TypingNotification n) {
    if (n.chatId != _chat.chatId) return;
    if (n.userId == _currentUserId) return; // echo of our own emit
    if (!mounted) return;

    if (n.isTyping) {
      setState(() => _otherIsTyping = true);
      // Auto-clear in case the corresponding stop event never reaches us.
      _typingClearTimer?.cancel();
      _typingClearTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _otherIsTyping = false);
      });
    } else {
      _typingClearTimer?.cancel();
      setState(() => _otherIsTyping = false);
    }
  }

  void _onMessageInputChanged(String value) {
    if (value.trim().isEmpty) {
      _emitTypingStop();
      return;
    }
    _emitTypingStartThrottled();
    // Reset the auto-stop timer — if user pauses typing for 4s, send stop.
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(seconds: 4), _emitTypingStop);
  }

  void _emitTypingStartThrottled() {
    final now = DateTime.now();
    if (_lastTypingStartEmittedAt != null &&
        now.difference(_lastTypingStartEmittedAt!) <
            const Duration(seconds: 3)) {
      return;
    }
    _lastTypingStartEmittedAt = now;
    _typingActive = true;
    _socket?.emitTyping(chatId: _chat.chatId, isTyping: true);
  }

  void _emitTypingStop() {
    _typingStopTimer?.cancel();
    if (!_typingActive) return;
    _typingActive = false;
    _lastTypingStartEmittedAt = null;
    _socket?.emitTyping(chatId: _chat.chatId, isTyping: false);
  }

  // ─────────────────────────── Send ─────────────────────────────────────

  Future<void> _sendMessage() async {
    if (_editingMessage != null) {
      await _submitEdit();
      return;
    }
    final text = _messageController.text.trim();
    if (text.isEmpty || _chat.removedByMe) return;
    final outbox = _outbox;
    if (outbox == null) return;

    final reply = _replyingTo;
    setState(() => _replyingTo = null);
    _messageController.clear();
    _emitTypingStop();

    await outbox.enqueueText(
      chatId: _chat.chatId,
      body: text,
      senderId: _currentUserId,
      replyToId: reply?.id,
    );
  }

  /// Single entry point — opens the system gallery showing both images
  /// and videos in one picker. We detect the kind from the file's
  /// MIME / extension and dispatch.
  Future<void> _pickMedia() async {
    if (_chat.removedByMe) return;

    final XFile? picked = await _picker.pickMedia();
    if (picked == null || !mounted) return;

    final mime = ChatService.mimeFromFilename(picked.name) ??
        (picked.mimeType ?? '');
    final isVideo = mime.startsWith('video/');
    if (isVideo) {
      await _handleVideoPicked(picked);
    } else {
      await _handleImagePicked(picked);
    }
  }

  Future<void> _handleImagePicked(XFile image) async {
    if (_chat.removedByMe) return;
    final outbox = _outbox;
    if (outbox == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    final result = await showMediaPreview(
      context: context,
      imageBytes: bytes,
    );
    if (result == null || !mounted) return;

    final reply = _replyingTo;
    setState(() => _replyingTo = null);

    // If the user edited the image inside the preview, prefer the edited
    // bytes (re-encoded JPEG by `pro_image_editor`) over the original.
    final editedBytes = result.editedImageBytes;
    final outgoingBytes = editedBytes ?? bytes;
    final outgoingFilename =
        editedBytes != null ? 'edited.jpg' : image.name;
    final outgoingContentType = editedBytes != null
        ? 'image/jpeg'
        : (ChatService.mimeFromFilename(image.name) ?? 'image/jpeg');
    // The original file path on disk no longer matches the bytes after an
    // edit — fall back to the in-memory bytes path in that case.
    final outgoingFilePath =
        (kIsWeb || editedBytes != null) ? null : image.path;

    await outbox.enqueueImage(
      chatId: _chat.chatId,
      senderId: _currentUserId,
      bytes: outgoingBytes,
      filePath: outgoingFilePath,
      caption: result.caption,
      replyToId: reply?.id,
      filename: outgoingFilename,
      contentType: outgoingContentType,
    );
  }

  Future<void> _handleVideoPicked(XFile picked) async {
    if (_chat.removedByMe) return;
    final outbox = _outbox;
    if (outbox == null) return;

    // Backend caps videos at 100MB. Reject early — `length()` is a cheap
    // file stat, no codec init.
    final lengthBytes = await picked.length();
    if (lengthBytes > 100 * 1024 * 1024) {
      _showError('Videos must be smaller than 100MB');
      return;
    }
    if (!mounted) return;

    // Open the preview immediately. The preview owns the only
    // VideoPlayerController we need (no pre-probe), generates its own
    // thumbnail in parallel with controller init, and enforces the
    // duration cap with a banner + disabled Send. Metadata + thumbnail
    // come back in [MediaPreviewResult].
    final result = await showMediaPreview(
      context: context,
      videoFilePath: kIsWeb ? null : picked.path,
      videoUrl: kIsWeb ? picked.path : null,
    );
    if (result == null || !mounted) return;

    final width = result.videoWidth;
    final height = result.videoHeight;
    final durationSeconds = result.videoDurationSeconds;
    if (width == null || height == null || durationSeconds == null) {
      // Should be unreachable — preview disables Send until probed —
      // but guard so we never enqueue a video with zeroed metadata.
      _showError('Could not read video');
      return;
    }
    final thumbBytes = result.videoThumbnailBytes ?? Uint8List(0);
    final caption = result.caption;

    final outgoingPath = result.editedVideoPath ?? picked.path;
    final wasEdited = result.editedVideoPath != null;

    final reply = _replyingTo;
    setState(() => _replyingTo = null);

    // After editing, the file is always mp4 (pro_video_editor's output
    // format). Otherwise honor the picker's MIME.
    final contentType = wasEdited
        ? 'video/mp4'
        : (ChatService.mimeFromFilename(picked.name) ?? 'video/mp4');
    final outgoingFilename = wasEdited ? 'edited.mp4' : picked.name;

    // On native, hand the file path to the outbox — it streams from disk
    // during upload (no 100MB blob in memory). On web we have no path
    // and have to read into memory.
    Uint8List? bytesFallback;
    if (kIsWeb) bytesFallback = await XFile(outgoingPath).readAsBytes();
    if (!mounted) return;

    await outbox.enqueueVideo(
      chatId: _chat.chatId,
      senderId: _currentUserId,
      videoFilePath: kIsWeb ? null : outgoingPath,
      videoBytes: bytesFallback,
      thumbnailBytes: thumbBytes,
      width: width,
      height: height,
      durationSeconds: durationSeconds,
      contentType: contentType,
      caption: caption,
      replyToId: reply?.id,
      filename: outgoingFilename,
    );
  }

  // ─────────────────────────── Reply / unsend ───────────────────────────

  void _replyToMessage(MessageEntity message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _retryMessage(MessageEntity message) async {
    final outbox = _outbox;
    if (outbox == null) return;
    await outbox.retry(message.clientId);
  }

  void _startEditing(MessageEntity message) {
    setState(() {
      _editingMessage = message;
      _replyingTo = null;
    });
    _messageController.text = message.body ?? '';
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    // Re-emit typing.stop because populating the field doesn't fire onChanged.
    _emitTypingStop();
  }

  void _cancelEditing() {
    setState(() => _editingMessage = null);
    _messageController.clear();
  }

  Future<void> _submitEdit() async {
    final editing = _editingMessage;
    if (editing == null) return;
    final newBody = _messageController.text.trim();
    if (newBody.isEmpty) return;
    if (newBody == editing.body) {
      _cancelEditing();
      return;
    }
    final id = editing.id;
    if (id == null) {
      // Edit a not-yet-sent message: just rewrite the local row in place,
      // the outbox will pick up the new body on the next drain attempt.
      _cancelEditing();
      return;
    }

    setState(() => _editSubmitting = true);
    try {
      final updated = await ChatService.editMessage(
        chatId: _chat.chatId,
        messageId: id,
        body: newBody,
      );
      if (!mounted) return;
      await _repo?.upsertMessage(updated);
      setState(() {
        _editingMessage = null;
        _editSubmitting = false;
      });
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _editSubmitting = false);
      _showError('Failed to edit');
    }
  }

  void _openMediaViewer(MessageEntity message) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, anim, _) => FadeTransition(
          opacity: anim,
          child: message.hasVideo
              ? VideoViewer(message: message)
              : ImageViewer(message: message),
        ),
      ),
    );
  }

  Future<void> _unsendMessage(MessageEntity message) async {
    final id = message.id;
    final repo = _repo;
    if (id == null) {
      // Send hadn't completed yet — just drop the local row + outbox row.
      if (repo != null) {
        await repo.db.deleteOutboxByClientId(message.clientId);
        await (repo.db.delete(repo.db.messages)
              ..where((m) => m.clientId.equals(message.clientId)))
            .go();
      }
      return;
    }
    // Optimistic: blank out + mark deleted locally.
    if (repo != null) {
      await repo.markMessageDeleted(
        messageId: id,
        deletedAt: DateTime.now().toUtc(),
      );
    }
    try {
      await ChatService.unsendMessage(
        chatId: _chat.chatId,
        messageId: id,
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to unsend');
    }
  }

  // ─────────────────────────── Unmatch ──────────────────────────────────

  Future<void> _confirmAndUnmatch() async {
    try {
      await MatchingService.unmatch(_chat.matchId);
      if (!mounted) return;
      await _repo?.setRemovedByMe(_chat.chatId, true);
      setState(() {
        _chat = _chat.copyWith(removedByMe: true);
        _replyingTo = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to unmatch');
    }
  }

  // ─────────────────────────── Misc helpers ─────────────────────────────

  bool _isMine(MessageEntity m) {
    if (m.isSystem) return false;
    if (_currentUserId != null) return m.senderId == _currentUserId;
    return m.status != MessageStatus.sent;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _openContactProfile() {
    final user = findUserByName(_chat.otherUser.name);
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProfileScreen(
          user: user,
          mode: ProfileViewMode.chat,
        ),
      ),
    );
  }

  void _openSafetyToolkit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Safety Toolkit',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Unmatch (hidden when already unmatched)
            if (!_chat.removedByMe) ...[
              _buildSafetyItem(
                icon: Icons.cancel_rounded,
                iconColor: const Color(0xFFFFC107),
                title: 'UNMATCH FROM ${_chat.otherUser.name.toUpperCase()}',
                description:
                    "No longer interested? Remove them from your matches.",
                onTap: () {
                  Navigator.pop(context);
                  _showUnmatchConfirmation();
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: AppColors.divider, height: 1),
              ),
            ],

            // Report
            _buildSafetyItem(
              icon: Icons.flag_rounded,
              iconColor: AppColors.primary,
              title: 'REPORT ${_chat.otherUser.name.toUpperCase()}',
              description: "Don't worry—we won't tell them.",
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.divider, height: 1),
            ),

            // Block
            _buildSafetyItem(
              icon: Icons.block_rounded,
              iconColor: AppColors.textPrimary,
              title: 'BLOCK ${_chat.otherUser.name.toUpperCase()}',
              description: "You won't see them, and they won't see you.",
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation();
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.divider, height: 1),
            ),

            _buildSafetyItem(
              icon: Icons.shield_rounded,
              iconColor: const Color(0xFF6C5CE7),
              title: 'ACCESS SAFETY CENTER',
              description:
                  'Your well-being matters. Find safety resources and tools here.',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textPrimary, size: 24),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Block ${_chat.otherUser.name}?',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "You won’t be able to undo this. Are you sure you want to continue?",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      // TODO: hook /blocks endpoint when backend ships it.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Yes, block',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Text(
                  "No, don't block",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnmatchConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textPrimary, size: 24),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unmatch ${_chat.otherUser.name}?',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "They will be removed from your matches and you won’t be able to chat with them anymore.",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmAndUnmatch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Yes, unmatch',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Text(
                  "No, don't unmatch",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // ─────────────────────────── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _openContactProfile,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        ClipOval(
                          child: _chat.otherUser.photoUrl == null
                              ? const _AvatarPlaceholder(size: 40)
                              : Image.network(
                                  _chat.otherUser.photoUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const _AvatarPlaceholder(size: 40),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _chat.otherUser.name,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_otherIsTyping)
                                Text(
                                  'typing…',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _openSafetyToolkit,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesArea()),
          if (_editingMessage != null && !_chat.removedByMe)
            _buildEditingPreview(),
          if (_replyingTo != null &&
              _editingMessage == null &&
              !_chat.removedByMe)
            _buildReplyPreview(),
          if (_chat.removedByMe) _buildUnmatchedBanner() else _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    final repo = _repo;
    if (repo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show a spinner only if local DB is empty AND the network backfill
    // hasn't completed yet.
    if (_messages.isEmpty && !_initialBackfilled) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty && _backfillFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load messages',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _backfillFromServer,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final visible = _messages.where(_isVisible).toList(growable: false);

    // Reversed-ListView layout (the WhatsApp/Telegram pattern):
    //   index 0          → newest message, anchored to the visual bottom
    //   index visible-1  → oldest message, near the visual top
    //   index visible    → "loading older" spinner (if active)
    //   index visible(+1)→ static match header at the very top
    //
    // Benefits:
    //   • No scroll-to-bottom hack on open — newest is already visible
    //   • New incoming/outgoing messages appear at the bottom naturally
    //   • Pagination at the top doesn't shift the user's scroll position
    final headerSlots = 1 + (_loadingOlder ? 1 : 0);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: visible.length + headerSlots,
        itemBuilder: (context, index) {
          // Top of the visual stack (highest index in a reversed list).
          if (index == visible.length + headerSlots - 1) {
            return _MatchHeader(name: _chat.otherUser.name);
          }
          if (_loadingOlder && index == visible.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          // Convert reversed index → chronological index.
          final msgIndex = visible.length - 1 - index;
          final message = visible[msgIndex];
          final mine = _isMine(message);
          // Show a timestamp above any message that starts a >15min gap.
          final showTimestamp = msgIndex == 0 ||
              message.createdAt
                      .difference(visible[msgIndex - 1].createdAt)
                      .inMinutes >
                  15;

          return Column(
            children: [
              if (showTimestamp)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              _MessageBubble(
                message: message,
                isMine: mine,
                contactName: _chat.otherUser.name,
                replyTarget: _resolveReply(message),
                onReply: () => _replyToMessage(message),
                onUnsend: mine ? () => _showUnsendDialog(message) : null,
                onEdit: mine &&
                        message.kind == MessageKind.text &&
                        !message.isDeleted
                    ? () => _startEditing(message)
                    : null,
                onRetry: mine && message.status == MessageStatus.failed
                    ? () => _retryMessage(message)
                    : null,
                onOpenImage: message.hasMedia
                    ? () => _openMediaViewer(message)
                    : null,
                otherUserLastReadAt: _chat.otherUserLastReadAt,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isVisible(MessageEntity m) {
    if (m.isSystem) return false;
    if (m.isDeleted) return false;
    return true;
  }

  MessageEntity? _resolveReply(MessageEntity m) {
    final targetId = m.replyToId;
    if (targetId == null) return null;
    for (final candidate in _messages) {
      if (candidate.id == targetId) return candidate;
    }
    return null;
  }

  Widget _buildReplyPreview() {
    final reply = _replyingTo!;
    final senderLabel = _isMine(reply) ? 'You' : _chat.otherUser.name;
    return Container(
      color: AppColors.inputFill,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyPreviewText(reply),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textHint, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingPreview() {
    return Container(
      color: AppColors.inputFill,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing message',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editingMessage?.body ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelEditing,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textHint, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildUnmatchedBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Center(
        child: Text(
          'You unmatched ${_chat.otherUser.name}',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        10,
        8,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _pickMedia,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                // Galleries with both images and videos — same icon used
                // by WhatsApp / Telegram for the "attach media" button.
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onChanged: _onMessageInputChanged,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _editSubmitting ? null : _sendMessage,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: _editSubmitting
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnsendDialog(MessageEntity message) {
    final isText = message.kind == MessageKind.text;
    final canEdit = isText && !message.isDeleted && message.id != null;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply_rounded,
                  color: AppColors.textPrimary),
              title: Text(
                'Reply',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _replyToMessage(message);
              },
            ),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppColors.textPrimary),
                title: Text(
                  'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _startEditing(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: Text(
                'Unsend Message',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _unsendMessage(message);
              },
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

// ── Match header at top of chat ──
class _MatchHeader extends StatelessWidget {
  final String name;

  const _MatchHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'You matched with $name',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start exchanging skills!',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ──
class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;
  final String contactName;
  final MessageEntity? replyTarget;
  final VoidCallback onReply;
  final VoidCallback? onUnsend;
  final VoidCallback? onEdit;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenImage;
  final DateTime? otherUserLastReadAt;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.contactName,
    required this.replyTarget,
    required this.onReply,
    this.onUnsend,
    this.onEdit,
    this.onRetry,
    this.onOpenImage,
    this.otherUserLastReadAt,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = message.hasMedia;
    final isFailed = message.status == MessageStatus.failed;
    final isSending = message.status == MessageStatus.sending;

    return GestureDetector(
      onLongPress: () {
        if (isMine) {
          onUnsend?.call();
        } else {
          _showReceivedOptions(context);
        }
      },
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 3,
            bottom: 3,
            left: isMine ? 60 : 0,
            right: isMine ? 0 : 60,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (replyTarget != null) _replyChip(context, replyTarget!),
              Opacity(
                opacity: isSending ? 0.7 : 1,
                child: Container(
                  padding: hasMedia
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.primary : AppColors.inputFill,
                    gradient: isMine ? AppColors.primaryGradient : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMine ? 20 : 6),
                      bottomRight: Radius.circular(isMine ? 6 : 20),
                    ),
                  ),
                  child: hasMedia
                      ? GestureDetector(
                          onTap: onOpenImage,
                          child: _buildImageWithCaption(isMine),
                        )
                      : _buildTextWithInlineStatus(isMine),
                ),
              ),
              if (isFailed) _buildFailedPill(),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders a text bubble's content with the status indicator (checks /
  /// clock / "edited" label) tucked inline at the bottom-right inside the
  /// bubble — the WhatsApp pattern. For short messages the status sits on
  /// the same line as the last word; long messages wrap and the status
  /// drops to its own bottom-right slot.
  Widget _buildTextWithInlineStatus(bool isMine) {
    final body = message.body ?? '';
    final inlineStatus = _buildInlineStatus(isMine);
    if (inlineStatus == null) {
      return Text(
        body,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: isMine ? Colors.white : AppColors.textPrimary,
          height: 1.35,
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // The hidden text below reserves enough trailing whitespace on the
        // last line so the absolute-positioned status doesn't overlap.
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: Text.rich(
            TextSpan(
              text: body,
              children: [
                // Invisible spacer so the status fits at the end of the
                // last text line — width chosen to leave room for either
                // the clock or the longest "edited ✓✓" combo.
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: SizedBox(width: _statusReservedWidth()),
                ),
              ],
            ),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isMine ? Colors.white : AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6, top: 2),
          child: inlineStatus,
        ),
      ],
    );
  }

  /// How much horizontal space to reserve at the end of the last text line
  /// so the inline status row never overlaps the text.
  double _statusReservedWidth() {
    final isSending = message.status == MessageStatus.sending;
    final isSent = message.status == MessageStatus.sent;
    final hasEdited = message.isEdited;
    final showChecks = isMine && message.id != null && isSent;

    if (isSending) return 18;
    if (showChecks && hasEdited) return 64; // "edited" + ✓✓
    if (showChecks) return 22; // ✓✓
    if (hasEdited) return 48; // "edited"
    return 0;
  }

  Widget _buildFailedPill() {
    return GestureDetector(
      onTap: onRetry,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 14, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              onRetry != null
                  ? 'Failed to send · Tap to retry'
                  : 'Failed to send',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Inline status — clock / check marks / "edited" — designed to sit
  /// inside the bubble at the bottom-right (WhatsApp pattern). Returns
  /// null when there's nothing to render (e.g. an incoming message has no
  /// status indicator on our side).
  Widget? _buildInlineStatus(bool isMine) {
    final isSending = message.status == MessageStatus.sending;
    final isSent = message.status == MessageStatus.sent;
    final showChecks = isMine && message.id != null && isSent;
    final showEdited = message.isEdited;
    final isReadByPeer = isMine &&
        otherUserLastReadAt != null &&
        !message.createdAt.isAfter(otherUserLastReadAt!);

    // Inside a coral bubble we use white-tinted icons; outside (gray
    // bubble for received messages) we use the muted text-hint color.
    final mutedColor =
        isMine ? Colors.white.withValues(alpha: 0.75) : AppColors.textHint;
    final readColor = isMine ? Colors.white : AppColors.primary;

    if (isSending) {
      return Icon(Icons.access_time_rounded, size: 12, color: mutedColor);
    }
    if (!showEdited && !showChecks) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showEdited)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'edited',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: mutedColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (showChecks)
          Icon(
            isReadByPeer ? Icons.done_all_rounded : Icons.done_rounded,
            size: 14,
            color: isReadByPeer ? readColor : mutedColor,
          ),
      ],
    );
  }

  Widget _replyChip(BuildContext context, MessageEntity target) {
    final senderLabel = target.senderId == null
        ? contactName
        : (isMineForTarget(target) ? 'You' : contactName);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMine
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.5,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _replyPreviewText(target),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool isMineForTarget(MessageEntity target) {
    return target.senderId != null && message.senderId == target.senderId;
  }

  Widget _buildImageWithCaption(bool isMine) {
    final caption = message.mediaCaption?.trim();
    final hasCaption = caption != null && caption.isNotEmpty;
    final inlineStatus = _buildInlineStatus(isMine);

    final imageRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft:
          hasCaption ? Radius.zero : Radius.circular(isMine ? 20 : 6),
      bottomRight:
          hasCaption ? Radius.zero : Radius.circular(isMine ? 6 : 20),
    );

    final imageWidget = ClipRRect(
      borderRadius: imageRadius,
      child: _buildImage(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Caption-less images: overlay the status pill on the image's
        // bottom-right with a translucent backdrop so it stays legible
        // over any photo (the WhatsApp pattern).
        if (!hasCaption && inlineStatus != null)
          Stack(
            children: [
              imageWidget,
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Force light glyphs on the dark backdrop regardless of
                  // bubble side — this overlay sits on a photo, not a
                  // coral bubble.
                  child: IconTheme(
                    data: const IconThemeData(
                        color: Colors.white, size: 14),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(color: Colors.white),
                      child: inlineStatus,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          imageWidget,
        if (hasCaption)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: inlineStatus == null
                ? Text(
                    caption,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color:
                          isMine ? Colors.white : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  )
                : Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: caption,
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child:
                                  SizedBox(width: _statusReservedWidth()),
                            ),
                          ],
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isMine
                              ? Colors.white
                              : AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: inlineStatus,
                      ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    final bytes = message.localImageBytes;
    final path = message.localImagePath;
    final isVideo = message.hasVideo;

    // Local optimistic preview (shown while uploading or during the brief
    // moment between optimistic insert and server confirm). Prefer the
    // file path on native — Flutter's image cache decodes the file once
    // and we never hold the bytes in RAM.
    Widget? localPreview;
    if (path != null) {
      localPreview = Image.file(
        File(path),
        width: 220,
        height: 280,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (bytes != null) {
      localPreview = Image.memory(
        bytes,
        width: 220,
        height: 280,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    if (localPreview != null) {
      return Stack(
        children: [
          localPreview,
          if (isVideo) _videoOverlay(),
          if (message.status == MessageStatus.sending)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Server-confirmed: video uses the dedicated thumbnailUrl, image uses
    // the mediaUrl directly.
    final url = isVideo ? message.mediaThumbnailUrl : message.mediaUrl;
    if (url == null) {
      return const SizedBox(
        width: 220,
        height: 280,
        child: ColoredBox(
          color: AppColors.inputFill,
          child: Icon(Icons.broken_image_rounded,
              color: AppColors.textHint, size: 40),
        ),
      );
    }
    final networkImage = Image.network(
      url,
      width: 220,
      height: 280,
      fit: BoxFit.cover,
      // Smoothly fade the image in once it's available so the swap from
      // placeholder → image isn't a hard cut.
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: child,
        );
      },
      // Placeholder + spinner while bytes are streaming in. Shows a
      // determinate ring once the server reports a Content-Length.
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final value = progress.expectedTotalBytes != null
            ? progress.cumulativeBytesLoaded /
                progress.expectedTotalBytes!
            : null;
        return Container(
          width: 220,
          height: 280,
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: value,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
              backgroundColor:
                  AppColors.textHint.withValues(alpha: 0.25),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => Container(
        width: 220,
        height: 280,
        color: AppColors.inputFill,
        child: const Icon(Icons.broken_image_rounded,
            color: AppColors.textHint, size: 40),
      ),
    );
    if (!isVideo) return networkImage;
    return Stack(children: [networkImage, _videoOverlay()]);
  }

  /// Big play button + duration label that sit on top of a video poster.
  Widget _videoOverlay() {
    final duration = message.mediaDurationSeconds;
    return Positioned.fill(
      child: Stack(
        children: [
          // Center play button.
          const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x66000000),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ),
          // Bottom-left duration pill.
          if (duration != null)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _formatVideoDuration(duration),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReceivedOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply_rounded,
                  color: AppColors.textPrimary),
              title: Text(
                'Reply',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onReply();
              },
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

/// Text shown in a reply chip / reply preview for the message being replied
/// to. Mirrors the chat-list preview rule: image / video with caption →
/// "📷|🎬 caption", media without → "📷 Photo" / "🎬 Video", text → body.
String _replyPreviewText(MessageEntity m) {
  if (m.hasImage) {
    final c = m.mediaCaption?.trim();
    return (c != null && c.isNotEmpty) ? '📷 $c' : '📷 Photo';
  }
  if (m.hasVideo) {
    final c = m.mediaCaption?.trim();
    return (c != null && c.isNotEmpty) ? '🎬 $c' : '🎬 Video';
  }
  return m.body ?? '';
}

/// "0:47" / "1:23" / "01:02:03" — same format as WhatsApp/Telegram.
String _formatVideoDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  if (h > 0) return '${two(h)}:${two(m)}:${two(s)}';
  return '$m:${two(s)}';
}

class _AvatarPlaceholder extends StatelessWidget {
  final double size;
  const _AvatarPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.inputFill,
      child: const Icon(Icons.person_rounded,
          color: AppColors.textHint, size: 22),
    );
  }
}
