import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/chat_models.dart';
import '../../services/chat_repository.dart';
import '../../services/chat_sync_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat/safety_bottom_sheet.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  StreamSubscription<List<ChatSummary>>? _chatsSub;
  ChatRepository? _repo;
  ChatSyncService? _sync;

  /// True for the very first sync of this app session — used to show a
  /// blocking spinner only if the local DB is empty too.
  bool _firstSyncInFlight = true;

  String? _syncError;
  List<ChatSummary> _chats = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = await ChatRepositoryHolder.instance();
    final sync = await ChatSyncServiceHolder.instance();
    if (!mounted) return;
    setState(() {
      _repo = repo;
      _sync = sync;
    });

    _chatsSub = repo.watchChats().listen((chats) {
      if (!mounted) return;
      setState(() => _chats = chats);
    });

    await _runSync();
  }

  /// Default refresh — what we run on mount and after returning from a chat
  /// detail. Skips re-fetching `/chats` once we have a sync cursor; the
  /// delta sync handles incremental updates without clobbering local state
  /// (e.g. unread counts cleared by an in-flight `markRead`).
  Future<void> _runSync({bool force = false}) async {
    final sync = _sync;
    if (sync == null) return;
    setState(() => _syncError = null);
    try {
      await sync.hydrate(force: force);
      await sync.syncDelta();
      if (!mounted) return;
      setState(() {
        _firstSyncInFlight = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _firstSyncInFlight = false;
        _syncError = 'Could not refresh chats';
      });
    }
  }

  /// Pull-to-refresh — explicit user gesture, force a full re-hydrate.
  Future<void> _forceRefresh() => _runSync(force: true);

  /// Chats with no real conversation yet (only the system "you matched"
  /// message, or no message at all). These render as the avatar carousel.
  List<ChatSummary> get _newMatches =>
      _chats.where((c) => c.isNewMatch).toList();

  /// Chats with at least one user message.
  List<ChatSummary> get _conversations =>
      _chats.where((c) => !c.isNewMatch).toList();

  List<ChatSummary> _filterByQuery(List<ChatSummary> source) {
    if (_query.isEmpty) return source;
    final q = _query.toLowerCase();
    return source.where((c) {
      if (c.otherUser.name.toLowerCase().contains(q)) return true;
      final preview = _previewText(c).toLowerCase();
      return preview.contains(q);
    }).toList();
  }

  void _openSafetyToolkit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SafetyBottomSheet(),
    );
  }

  Future<void> _openChat(ChatSummary chat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
    );
    // Local DB stream auto-updates on return, but kick a sync to catch any
    // events that happened while the chat was open (e.g. an unmatch).
    if (mounted) await _runSync();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMatches = _filterByQuery(_newMatches);
    final filteredConvos = _filterByQuery(_conversations);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: "Chat" + shield icon ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Text(
                  'Chat',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _openSafetyToolkit,
                  icon: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${_newMatches.length} Matches',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textHint, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _buildBody(filteredMatches, filteredConvos),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    List<ChatSummary> matches,
    List<ChatSummary> convos,
  ) {
    // Show a blocking spinner only if we have nothing local to render. After
    // first hydrate, the local DB streams in instantly even on slow networks.
    if (_repo == null || (_firstSyncInFlight && _chats.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_syncError != null && _chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_syncError!,
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _runSync, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _forceRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // ── New Matches section ──
          if (matches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'New Matches',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < matches.length - 1 ? 16 : 0,
                    ),
                    child: _MatchAvatar(
                      chat: match,
                      onTap: () => _openChat(match),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Messages section ──
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'Messages',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (convos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  _query.isNotEmpty
                      ? 'No results found'
                      : 'No conversations yet',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < convos.length; i++) ...[
              _ConversationTile(
                chat: convos[i],
                onTap: () => _openChat(convos[i]),
              ),
              if (i < convos.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 88),
                  child: Divider(
                    color: AppColors.divider,
                    height: 1,
                    thickness: 0.5,
                  ),
                ),
            ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Match avatar in horizontal scroll ──
class _MatchAvatar extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onTap;

  const _MatchAvatar({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = chat.otherUser.photoUrl;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGradient.colors.first,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: url == null
                      ? _avatarFallback()
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarFallback(),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              chat.otherUser.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _avatarFallback() => Container(
      color: AppColors.inputFill,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.textHint,
        size: 28,
      ),
    );

// ── Conversation tile ──
class _ConversationTile extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onTap;

  const _ConversationTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = chat.isUnread;
    final preview = _previewText(chat);
    final timeAgo = chat.lastMessage != null
        ? _formatTimeAgo(chat.lastMessage!.createdAt)
        : '';
    final url = chat.otherUser.photoUrl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            ClipOval(
              child: url == null
                  ? SizedBox(
                      width: 56,
                      height: 56,
                      child: _avatarFallback(),
                    )
                  : Image.network(
                      url,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => SizedBox(
                        width: 56,
                        height: 56,
                        child: _avatarFallback(),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherUser.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight:
                          isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.w400,
                      color: isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isUnread
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight:
                        isUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the chat-list preview line from the last message. Uses the
/// denormalized lastMessageId in chat row when the full message isn't loaded,
/// falling back to a generic preview.
String _previewText(ChatSummary chat) {
  final m = chat.lastMessage;
  if (m == null) return 'You matched! Say hi 👋';
  if (m.isDeleted) return 'Message unsent';
  switch (m.kind) {
    case MessageKind.text:
      return m.body ?? '';
    case MessageKind.image:
      final caption = m.mediaCaption?.trim();
      return caption != null && caption.isNotEmpty
          ? '📷 $caption'
          : '📷 Photo';
    case MessageKind.video:
      final caption = m.mediaCaption?.trim();
      return caption != null && caption.isNotEmpty
          ? '🎬 $caption'
          : '🎬 Video';
    case MessageKind.system:
      return m.body ?? 'You matched! Say hi 👋';
    case MessageKind.unknown:
      // The chat-row mapper returns a stub MessageEntity with `unknown` kind
      // when only the lastMessageId is known. Fall back to a sensible label.
      return chat.lastMessage?.body ?? 'New message';
  }
}

/// Tinder-style relative time — "now", "5m", "2h", "3d", or a date.
String _formatTimeAgo(DateTime when) {
  final diff = DateTime.now().toUtc().difference(when.toUtc());
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[when.month - 1]} ${when.day}';
}
