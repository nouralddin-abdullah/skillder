import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_storage.dart';
import 'chat_repository.dart';
import 'chat_service.dart';

/// Drives the local cache via two paths:
///
///   1. [hydrate] — full snapshot via `GET /chats` (used on cold start to
///      establish the chat list with `otherUser` data the sync deltas
///      don't carry).
///   2. [syncDelta] — incremental events via `GET /chats/sync?since=...`.
///      Drains until `hasMore` is false, then persists the new cursor.
class ChatSyncService {
  final ChatRepository repository;

  /// Ids of chats that the user currently has open. Lets us auto-mark new
  /// messages as read when they arrive on a focused chat, instead of
  /// growing the unread count.
  final Set<String> focusedChats = <String>{};

  /// Resolved lazily so we can hand it off to consumers (e.g. the chat
  /// detail screen needs it to decide which side to render bubbles on).
  String? currentUserId;

  bool _hydrating = false;
  bool _syncing = false;

  ChatSyncService(this.repository);

  Future<void> ensureUserId() async {
    currentUserId ??= await AuthStorage.getUserId();
  }

  /// First-run only: pulls a full chat list from the server and seeds the
  /// initial sync cursor. Subsequent calls are no-ops if a cursor already
  /// exists — at that point [syncDelta] is the canonical refresher.
  ///
  /// This protects local-only state (unread counts cleared by `markRead`,
  /// failed sends, optimistic edits) from being clobbered by a stale `/chats`
  /// snapshot that the server might still be processing reads against.
  Future<void> hydrate({bool force = false}) async {
    if (_hydrating) return;
    _hydrating = true;
    try {
      await ensureUserId();
      final hasCursor = (await repository.db.getCursor()) != null;
      if (force || !hasCursor) {
        final chats = await ChatService.listChats();
        await repository.replaceChats(chats);
      }
      if (!hasCursor) {
        final initial = await _fetchSync(null);
        await repository.db.setCursor(initial.newCursor);
      }
    } finally {
      _hydrating = false;
    }
  }

  /// Pull all events newer than the stored cursor and apply them. Re-issues
  /// the request while [SyncResult.hasMore] is true so a long offline
  /// stretch catches up in a single call to [syncDelta].
  ///
  /// Each page is applied inside one DB transaction so the chat-list and
  /// message streams emit a single coalesced update — no visible cycling
  /// when 6 of our own message events all arrive in the same delta.
  Future<void> syncDelta() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await ensureUserId();
      String? cursor = await repository.db.getCursor();
      bool needsRehydrate = false;

      while (true) {
        final result = await _fetchSync(cursor);
        if (result.events.isNotEmpty) {
          await repository.db.transaction(() async {
            for (final event in result.events) {
              if (await _applyEvent(event)) needsRehydrate = true;
            }
          });
        }
        cursor = result.newCursor;
        await repository.db.setCursor(cursor);
        if (!result.hasMore) break;
      }

      // Match.created / match.removed events arrive without `otherUser`
      // data, so we re-pull the canonical chat list to fill that in.
      if (needsRehydrate) {
        final chats = await ChatService.listChats();
        await repository.replaceChats(chats);
      }
    } finally {
      _syncing = false;
    }
  }

  // ─────────────────────────── Public event entry ──────────────────────

  /// Apply a single realtime event delivered out-of-band (e.g. from the
  /// Socket.IO gateway). Same code path as the sync-delta loop, just for
  /// one event at a time. Wraps the application in a transaction so
  /// downstream streams see a single coalesced update, and triggers a
  /// re-hydrate of `/chats` when the event implies a chat-list change
  /// (`match.created` / `match.removed`).
  Future<void> applyRealtimeEvent(Map<String, dynamic> raw) async {
    await ensureUserId();
    final event = RealtimeEvent.fromJson(raw);
    bool needsRehydrate = false;
    await repository.db.transaction(() async {
      needsRehydrate = await _applyEvent(event);
    });
    if (needsRehydrate) {
      try {
        final chats = await ChatService.listChats();
        await repository.replaceChats(chats);
      } catch (_) {
        // Best-effort. The next sync delta will reconcile.
      }
    }
  }

  // ─────────────────────────── Internals ───────────────────────────────

  /// Returns true when the event indicates the chat list itself has
  /// changed (new chat, removed chat) — meaning we should re-hydrate.
  Future<bool> _applyEvent(RealtimeEvent event) async {
    switch (event.type) {
      case 'message.created':
        await _onMessageCreated(event);
        return false;
      case 'message.edited':
        await _onMessageEdited(event);
        return false;
      case 'message.deleted':
        await _onMessageDeleted(event);
        return false;
      case 'message.read':
        await _onMessageRead(event);
        return false;
      case 'match.created':
        await _onMatchCreated(event);
        return true;
      case 'match.removed':
        await _onMatchRemoved(event);
        return false; // chat row stays; we only flip a flag
      default:
        return false;
    }
  }

  Future<void> _onMessageCreated(RealtimeEvent event) async {
    final m = MessageEntity.fromJson(event.data);
    await repository.upsertMessage(m);

    final chat = await repository.getChat(m.chatId);
    if (chat == null) return;

    final mine = m.senderId != null && m.senderId == currentUserId;
    final isSystem = m.kind == MessageKind.system;
    final isFocused = focusedChats.contains(m.chatId);

    // Don't double-increment for messages we've already marked-as-read
    // locally (their createdAt sits inside the read window).
    final alreadyRead = chat.lastReadAt != null &&
        !m.createdAt.isAfter(chat.lastReadAt!);

    final shouldIncrement =
        !mine && !isSystem && !isFocused && !alreadyRead;

    // Don't move `lastMessageId` backward when the sync delta replays
    // events for messages older than our current preview pointer (e.g.
    // we just sent 6 in a row and they all arrive via sync after we've
    // locally bumped to the newest one).
    final messageId = m.id;
    final isNewerThanCurrent = chat.lastMessage == null ||
        m.createdAt.isAfter(chat.lastMessage!.createdAt);

    if (messageId != null && (isNewerThanCurrent || shouldIncrement)) {
      await repository.bumpChatForNewMessage(
        chatId: m.chatId,
        messageId: messageId,
        at: m.createdAt,
        incrementUnread: shouldIncrement,
        // If the event is older than our current preview, only update the
        // unread counter (when applicable) without touching lastMessageId.
        keepCurrentLastMessage: !isNewerThanCurrent,
      );
    }
  }

  Future<void> _onMessageEdited(RealtimeEvent event) async {
    final m = MessageEntity.fromJson(event.data);
    await repository.upsertMessage(m);
  }

  Future<void> _onMessageDeleted(RealtimeEvent event) async {
    final messageId = event.data['messageId']?.toString();
    if (messageId == null) return;
    final raw = event.data['deletedAt'];
    final deletedAt = raw is String
        ? (DateTime.tryParse(raw) ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();
    await repository.markMessageDeleted(
      messageId: messageId,
      deletedAt: deletedAt,
    );
  }

  Future<void> _onMessageRead(RealtimeEvent event) async {
    final readerUserId = event.data['userId']?.toString();
    final lastReadAtRaw = event.data['lastReadAt'];
    final lastReadAt = lastReadAtRaw is String
        ? (DateTime.tryParse(lastReadAtRaw) ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();

    final chatId = event.chatId;
    if (chatId == null) return;

    // If the reader is us → reset our local unread count for this chat.
    if (readerUserId != null && readerUserId == currentUserId) {
      await repository.resetUnread(chatId: chatId, lastReadAt: lastReadAt);
      return;
    }
    // The other party read up to a message → record their pointer so the
    // chat detail can render ✓✓ on outgoing messages older than this.
    if (readerUserId != null) {
      await repository.setOtherUserLastReadAt(
        chatId: chatId,
        at: lastReadAt,
      );
    }
  }

  Future<void> _onMatchCreated(RealtimeEvent event) async {
    // Bare-bones row so a quick stream listener can react. The full
    // [otherUser] data is filled by the post-loop re-hydrate.
    final matchId = event.data['matchId']?.toString();
    final chatId = event.data['chatId']?.toString();
    if (matchId == null || chatId == null) return;

    final existing = await repository.getChat(chatId);
    if (existing != null) {
      // Resurrected — just clear the soft-removed flag.
      await repository.setRemovedByMe(chatId, false);
      return;
    }
    // First-time match — placeholder will be replaced by the rehydrate.
    await repository.upsertChat(ChatSummary(
      chatId: chatId,
      matchId: matchId,
      otherUser: const ChatOtherUser(id: '', name: '…'),
      lastMessage: null,
      unreadCount: 0,
      removedByMe: false,
    ));
  }

  Future<void> _onMatchRemoved(RealtimeEvent event) async {
    final chatId = event.data['chatId']?.toString();
    if (chatId == null) return;
    await repository.setRemovedByMe(chatId, true);
  }

  // ─────────────────────────── Sync HTTP ───────────────────────────────

  Future<_SyncResult> _fetchSync(String? cursor) async {
    final qp = <String, String>{};
    if (cursor != null) qp['since'] = cursor;
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/chats/sync').replace(queryParameters: qp);
    final token = await AuthStorage.getToken();
    final res = await http.get(uri, headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (res.statusCode < 200 || res.statusCode >= 300) {
      Map<String, dynamic>? body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {}
      throw ApiException(
        statusCode: res.statusCode,
        message: body?['message']?.toString() ?? 'Sync failed',
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final eventsRaw = data['events'];
    final events = <RealtimeEvent>[];
    if (eventsRaw is List) {
      for (final raw in eventsRaw) {
        if (raw is Map<String, dynamic>) events.add(RealtimeEvent.fromJson(raw));
      }
    }
    return _SyncResult(
      events: events,
      newCursor: data['newCursor']?.toString() ?? cursor ?? '0',
      hasMore: data['hasMore'] == true,
    );
  }
}

class _SyncResult {
  final List<RealtimeEvent> events;
  final String newCursor;
  final bool hasMore;
  const _SyncResult({
    required this.events,
    required this.newCursor,
    required this.hasMore,
  });
}

class RealtimeEvent {
  final String type;
  final String seq;
  final String? chatId;
  final Map<String, dynamic> data;

  const RealtimeEvent({
    required this.type,
    required this.seq,
    required this.chatId,
    required this.data,
  });

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return RealtimeEvent(
      type: json['type'] as String,
      seq: json['seq']?.toString() ?? '',
      chatId: json['chatId'] as String?,
      data: dataRaw is Map<String, dynamic>
          ? dataRaw
          : <String, dynamic>{},
    );
  }
}

/// Process-wide holder. The splash router resets this on logout so the
/// next user doesn't inherit the previous cursor.
class ChatSyncServiceHolder {
  static ChatSyncService? _instance;

  static Future<ChatSyncService> instance() async {
    final existing = _instance;
    if (existing != null) return existing;
    final repo = await ChatRepositoryHolder.instance();
    final created = ChatSyncService(repo);
    _instance = created;
    return created;
  }

  static void reset() {
    _instance = null;
  }
}
