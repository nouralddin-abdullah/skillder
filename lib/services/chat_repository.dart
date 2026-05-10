import 'package:drift/drift.dart' show Value;

import '../db/app_database.dart';
import '../models/chat_models.dart';

/// Singleton-style local cache + stream layer over [AppDatabase].
///
/// The UI never talks to the DB directly — it consumes the streams here so
/// every change (sync delta, optimistic send, REST hydrate) flows through
/// one well-known surface.
class ChatRepository {
  final AppDatabase _db;

  ChatRepository(this._db);

  AppDatabase get db => _db;

  // ─────────────────────────── Chat list ───────────────────────────────

  /// Joins each chat row with its actual last message (looked up by id) so
  /// the chat-list preview text + kind are populated, not just the id.
  Stream<List<ChatSummary>> watchChats() {
    return _db.watchChats().asyncMap((rows) async {
      final summaries = <ChatSummary>[];
      for (final row in rows) {
        summaries.add(await _hydrateChatSummary(row));
      }
      return summaries;
    });
  }

  Stream<ChatSummary?> watchChat(String chatId) {
    return _db.watchChat(chatId).asyncMap((row) async {
      if (row == null) return null;
      return _hydrateChatSummary(row);
    });
  }

  Future<ChatSummary?> getChat(String chatId) async {
    final row = await _db.getChat(chatId);
    if (row == null) return null;
    return _hydrateChatSummary(row);
  }

  Future<ChatSummary> _hydrateChatSummary(Chat row) async {
    MessageEntity? lastMessage;
    final lastId = row.lastMessageId;
    if (lastId != null) {
      final msgRow = await _db.getMessageById(lastId);
      if (msgRow != null) {
        lastMessage = _messageRowToEntity(msgRow);
      }
    }
    return _chatRowToSummary(row, lastMessage: lastMessage);
  }

  /// Replace the whole chat-list snapshot — used after `GET /chats` or after
  /// receiving any `match.created` / `match.removed` event that needs a full
  /// re-hydrate (since the event payload doesn't carry `otherUser`).
  Future<void> replaceChats(List<ChatSummary> remote) async {
    final remoteIds = remote.map((c) => c.chatId).toSet();

    // Remove chats the server no longer has (e.g. blocked / hard-deleted).
    final localChats = await _db.select(_db.chats).get();
    for (final local in localChats) {
      if (!remoteIds.contains(local.chatId)) {
        await _db.deleteChat(local.chatId);
      }
    }

    // Upsert everything we got.
    for (final c in remote) {
      await _upsertChatSummary(c);
    }
  }

  Future<void> upsertChat(ChatSummary chat) => _upsertChatSummary(chat);

  Future<void> _upsertChatSummary(ChatSummary c) async {
    await _db.upsertChat(ChatsCompanion(
      chatId: Value(c.chatId),
      matchId: Value(c.matchId),
      otherUserId: Value(c.otherUser.id),
      otherUserName: Value(c.otherUser.name),
      otherUserPhotoUrl: Value(c.otherUser.photoUrl),
      unreadCount: Value(c.unreadCount),
      lastReadAt: Value(c.lastReadAt),
      removedByMe: Value(c.removedByMe),
      lastMessageId: Value(c.lastMessage?.id),
      lastMessageAt: Value(c.lastMessage?.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
    final last = c.lastMessage;
    if (last != null) {
      await _db.upsertMessage(_messageEntityToCompanion(last));
    }
  }

  Future<void> setRemovedByMe(String chatId, bool value) =>
      _db.setRemovedByMe(chatId: chatId, value: value);

  Future<void> deleteChat(String chatId) => _db.deleteChat(chatId);

  Future<void> wipe() => _db.wipe();

  // ─────────────────────────── Messages ────────────────────────────────

  Stream<List<MessageEntity>> watchMessages(String chatId) {
    return _db.watchMessagesForChat(chatId).map(
          (rows) => rows.map(_messageRowToEntity).toList(growable: false),
        );
  }

  Future<void> upsertMessages(Iterable<MessageEntity> messages) async {
    await _db.transaction(() async {
      for (final m in messages) {
        await _upsertOne(m);
      }
    });
  }

  Future<void> upsertMessage(MessageEntity message) => _upsertOne(message);

  Future<void> _upsertOne(MessageEntity m) async {
    // Preserve a later local createdAt to keep optimistic-send ordering
    // stable. If we wrote `now+1ms` because the server clock was ahead,
    // we don't want a subsequent server confirm or sync delta to drag
    // the bubble back to its earlier server-issued timestamp.
    DateTime createdAt = m.createdAt;
    final clientId = m.clientId;
    if (clientId.isNotEmpty) {
      final existing = await _db.getMessageByClientId(clientId);
      if (existing != null && existing.createdAt.isAfter(createdAt)) {
        createdAt = existing.createdAt;
      }
    }
    await _db.upsertMessage(
      _messageEntityToCompanion(m.copyWith(createdAt: createdAt)),
    );
  }

  Future<void> markMessageStatus({
    required String clientId,
    required MessageStatus status,
  }) =>
      _db.markMessageStatus(
        clientId: clientId,
        status: _statusToString(status),
      );

  /// Apply a `message.deleted` event — sets `deletedAt`, blanks contents.
  Future<void> markMessageDeleted({
    required String messageId,
    required DateTime deletedAt,
  }) async {
    final row = await _db.getMessageById(messageId);
    if (row == null) return;
    await _db.upsertMessage(MessagesCompanion(
      clientId: Value(row.clientId),
      id: Value(row.id),
      chatId: Value(row.chatId),
      senderId: Value(row.senderId),
      kind: Value(row.kind),
      body: const Value(null),
      mediaUrl: const Value(null),
      mediaCaption: const Value(null),
      replyToId: Value(row.replyToId),
      editedAt: Value(row.editedAt),
      deletedAt: Value(deletedAt),
      createdAt: Value(row.createdAt),
      status: Value(row.status),
    ));
  }

  /// Recompute denormalized chat fields after a new message has been
  /// upserted. Increments [unreadCount] when [incrementUnread] is true.
  /// Updates the `lastMessageId/At` pointer unless [keepCurrentLastMessage]
  /// is set — used by sync to skip stale events that would visually
  /// rewind the chat-list preview.
  Future<void> bumpChatForNewMessage({
    required String chatId,
    required String messageId,
    required DateTime at,
    required bool incrementUnread,
    bool keepCurrentLastMessage = false,
  }) async {
    final chat = await _db.getChat(chatId);
    if (chat == null) return;
    await _db.upsertChat(ChatsCompanion(
      chatId: Value(chat.chatId),
      matchId: Value(chat.matchId),
      otherUserId: Value(chat.otherUserId),
      otherUserName: Value(chat.otherUserName),
      otherUserPhotoUrl: Value(chat.otherUserPhotoUrl),
      lastReadAt: Value(chat.lastReadAt),
      removedByMe: Value(chat.removedByMe),
      unreadCount: Value(
        incrementUnread ? chat.unreadCount + 1 : chat.unreadCount,
      ),
      lastMessageId: keepCurrentLastMessage
          ? Value(chat.lastMessageId)
          : Value(messageId),
      lastMessageAt: keepCurrentLastMessage
          ? Value(chat.lastMessageAt)
          : Value(at),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> resetUnread({
    required String chatId,
    required DateTime lastReadAt,
  }) =>
      _db.setUnreadCount(
        chatId: chatId,
        count: 0,
        lastReadAt: lastReadAt,
      );

  // ─────────────────────────── Mappers ─────────────────────────────────

  ChatSummary _chatRowToSummary(
    Chat row, {
    MessageEntity? lastMessage,
  }) {
    return ChatSummary(
      chatId: row.chatId,
      matchId: row.matchId,
      otherUser: ChatOtherUser(
        id: row.otherUserId,
        name: row.otherUserName,
        photoUrl: row.otherUserPhotoUrl,
      ),
      lastMessage: lastMessage,
      unreadCount: row.unreadCount,
      lastReadAt: row.lastReadAt,
      otherUserLastReadAt: row.otherUserLastReadAt,
      removedByMe: row.removedByMe,
    );
  }

  Future<void> setOtherUserLastReadAt({
    required String chatId,
    required DateTime at,
  }) =>
      _db.setOtherUserLastReadAt(chatId: chatId, at: at);

  MessageEntity _messageRowToEntity(Message row) {
    return MessageEntity(
      id: row.id,
      clientId: row.clientId,
      chatId: row.chatId,
      senderId: row.senderId,
      kind: parseMessageKind(row.kind),
      body: row.body,
      mediaUrl: row.mediaUrl,
      mediaThumbnailUrl: row.mediaThumbnailUrl,
      mediaCaption: row.mediaCaption,
      mediaWidth: row.mediaWidth,
      mediaHeight: row.mediaHeight,
      mediaDurationSeconds: row.mediaDurationSeconds,
      replyToId: row.replyToId,
      editedAt: row.editedAt,
      deletedAt: row.deletedAt,
      createdAt: row.createdAt,
      status: _statusFromString(row.status),
    );
  }

  MessagesCompanion _messageEntityToCompanion(MessageEntity m) {
    final clientId = m.clientId.isNotEmpty
        ? m.clientId
        : (m.id ?? 'srv:${m.chatId}:${m.createdAt.microsecondsSinceEpoch}');
    return MessagesCompanion(
      id: Value(m.id),
      clientId: Value(clientId),
      chatId: Value(m.chatId),
      senderId: Value(m.senderId),
      kind: Value(_kindToString(m.kind)),
      body: Value(m.body),
      mediaUrl: Value(m.mediaUrl),
      mediaThumbnailUrl: Value(m.mediaThumbnailUrl),
      mediaCaption: Value(m.mediaCaption),
      mediaWidth: Value(m.mediaWidth),
      mediaHeight: Value(m.mediaHeight),
      mediaDurationSeconds: Value(m.mediaDurationSeconds),
      replyToId: Value(m.replyToId),
      editedAt: Value(m.editedAt),
      deletedAt: Value(m.deletedAt),
      createdAt: Value(m.createdAt),
      status: Value(_statusToString(m.status)),
    );
  }

  String _kindToString(MessageKind k) => switch (k) {
        MessageKind.text => 'text',
        MessageKind.image => 'image',
        MessageKind.video => 'video',
        MessageKind.system => 'system',
        MessageKind.unknown => 'unknown',
      };

  String _statusToString(MessageStatus s) => switch (s) {
        MessageStatus.sending => 'sending',
        MessageStatus.sent => 'sent',
        MessageStatus.failed => 'failed',
      };

  MessageStatus _statusFromString(String s) => switch (s) {
        'sending' => MessageStatus.sending,
        'failed' => MessageStatus.failed,
        _ => MessageStatus.sent,
      };
}

/// Process-wide singleton holder. Lazily initialized; the splash router
/// calls [init] after the user logs in.
class ChatRepositoryHolder {
  static AppDatabase? _database;
  static ChatRepository? _repository;

  static Future<ChatRepository> instance() async {
    final repo = _repository;
    if (repo != null) return repo;
    final database = _database ??= AppDatabase();
    final created = ChatRepository(database);
    _repository = created;
    return created;
  }

  /// Wipe everything — call on logout so the next user doesn't see leftover
  /// chats from the previous session.
  static Future<void> reset() async {
    final repo = _repository;
    if (repo != null) await repo.wipe();
  }
}
