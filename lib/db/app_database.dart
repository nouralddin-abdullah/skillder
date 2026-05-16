import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─────────────────────────── Tables ────────────────────────────────────

/// One row per chat (i.e. per match) the user has access to. Hydrated
/// initially from `GET /chats` and kept fresh by sync deltas.
class Chats extends Table {
  TextColumn get chatId => text()();
  TextColumn get matchId => text()();
  TextColumn get otherUserId => text()();
  TextColumn get otherUserName => text()();
  TextColumn get otherUserPhotoUrl => text().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReadAt => dateTime().nullable()();

  /// The other party's last-read timestamp, learned via `message.read`
  /// events. Drives the ✓ vs ✓✓ render on outgoing messages. Null until
  /// the first `message.read` event arrives for this chat from the peer.
  DateTimeColumn get otherUserLastReadAt => dateTime().nullable()();

  BoolColumn get removedByMe =>
      boolean().withDefault(const Constant(false))();

  /// FK to [Messages.id] — denormalized for cheap chat-list ordering.
  TextColumn get lastMessageId => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();

  /// When this row was last touched locally — used as the chat-list sort
  /// fallback for chats that have no messages yet.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chatId};
}

/// Every message ever seen (or queued) in any chat. Optimistic sends are
/// inserted with `id = null` and `status = 'sending'`; the row is updated
/// in place when the server confirms.
class Messages extends Table {
  IntColumn get rowId => integer().autoIncrement()();

  /// Server-assigned UUID. Null while a send is in flight.
  TextColumn get id => text().nullable()();

  /// Client-generated UUID. Always set, unique across the table — backend
  /// enforces the same uniqueness for idempotent retries.
  TextColumn get clientId => text().unique()();

  TextColumn get chatId => text()();

  /// Null for system messages.
  TextColumn get senderId => text().nullable()();

  /// 'text' | 'image' | 'system'
  TextColumn get kind => text()();

  TextColumn get body => text().nullable()();
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaThumbnailUrl => text().nullable()();
  TextColumn get mediaCaption => text().nullable()();
  IntColumn get mediaWidth => integer().nullable()();
  IntColumn get mediaHeight => integer().nullable()();
  IntColumn get mediaDurationSeconds => integer().nullable()();
  TextColumn get replyToId => text().nullable()();

  DateTimeColumn get editedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  /// 'sending' | 'sent' | 'failed' — local UI lifecycle.
  TextColumn get status => text().withDefault(const Constant('sent'))();

  /// JSON-encoded `system_payload` from the backend (only set on system-kind
  /// messages — call records, future system events). Stored as TEXT because
  /// SQLite has no native JSONB type; consumers parse on read. Body remains
  /// the human-readable fallback for old rows + downlevel renderers.
  TextColumn get systemPayload => text().nullable()();
}

/// Singleton-ish key/value store for the delta-sync cursor and last-sync
/// timestamp. Use 'global' as the only key for now.
class SyncStateRows extends Table {
  TextColumn get key => text()();
  TextColumn get cursor => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Pending sends waiting to be POSTed (or retried). One row per
/// in-flight `clientId`. Once the server confirms, the row is deleted.
class OutboxRows extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  TextColumn get chatId => text()();
  TextColumn get kind => text()();
  TextColumn get body => text().nullable()();

  /// Set after the media upload step succeeds; while null + bytes/path are
  /// set, the upload still needs to happen.
  TextColumn get mediaUrl => text().nullable()();
  TextColumn get mediaThumbnailUrl => text().nullable()();
  TextColumn get mediaCaption => text().nullable()();
  TextColumn get mediaLocalPath => text().nullable()();
  BlobColumn get mediaLocalBytes => blob().nullable()();
  BlobColumn get mediaThumbnailLocalBytes => blob().nullable()();
  TextColumn get mediaFilename => text().nullable()();
  TextColumn get mediaContentType => text().nullable()();
  IntColumn get mediaWidth => integer().nullable()();
  IntColumn get mediaHeight => integer().nullable()();
  IntColumn get mediaDurationSeconds => integer().nullable()();

  TextColumn get replyToId => text().nullable()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// ─────────────────────────── Database ──────────────────────────────────

@DriftDatabase(tables: [Chats, Messages, SyncStateRows, OutboxRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing — lets a test pass an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(chats, chats.otherUserLastReadAt);
          }
          if (from < 3) {
            // New media metadata for video support + image enrichment.
            await m.addColumn(messages, messages.mediaThumbnailUrl);
            await m.addColumn(messages, messages.mediaWidth);
            await m.addColumn(messages, messages.mediaHeight);
            await m.addColumn(messages, messages.mediaDurationSeconds);
            await m.addColumn(outboxRows, outboxRows.mediaThumbnailUrl);
            await m.addColumn(
                outboxRows, outboxRows.mediaThumbnailLocalBytes);
            await m.addColumn(outboxRows, outboxRows.mediaContentType);
            await m.addColumn(outboxRows, outboxRows.mediaWidth);
            await m.addColumn(outboxRows, outboxRows.mediaHeight);
            await m.addColumn(outboxRows, outboxRows.mediaDurationSeconds);
          }
          if (from < 4) {
            // Calls feature: structured payload for system-kind messages
            // (currently call records: kind/duration/endReason/etc.).
            // Existing system messages stay null and continue to render
            // from `body` — the backend always writes both, so future
            // syncs will populate this column.
            await m.addColumn(messages, messages.systemPayload);
          }
        },
      );

  // ─────────────────────────── Chats ───────────────────────────────────

  Stream<List<Chat>> watchChats() {
    return (select(chats)
          ..orderBy([
            // Most recent activity first; chats with no message at all sort
            // by updatedAt as a fallback.
            (c) => OrderingTerm(
                  expression: c.lastMessageAt,
                  mode: OrderingMode.desc,
                ),
            (c) => OrderingTerm(
                  expression: c.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Stream<Chat?> watchChat(String chatId) {
    return (select(chats)..where((c) => c.chatId.equals(chatId)))
        .watchSingleOrNull();
  }

  Future<Chat?> getChat(String chatId) {
    return (select(chats)..where((c) => c.chatId.equals(chatId)))
        .getSingleOrNull();
  }

  Future<void> upsertChat(ChatsCompanion entry) async {
    await into(chats).insertOnConflictUpdate(entry);
  }

  Future<void> setRemovedByMe({
    required String chatId,
    required bool value,
  }) async {
    await (update(chats)..where((c) => c.chatId.equals(chatId)))
        .write(ChatsCompanion(
      removedByMe: Value(value),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> setUnreadCount({
    required String chatId,
    required int count,
    DateTime? lastReadAt,
  }) async {
    await (update(chats)..where((c) => c.chatId.equals(chatId)))
        .write(ChatsCompanion(
      unreadCount: Value(count),
      lastReadAt:
          lastReadAt == null ? const Value.absent() : Value(lastReadAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Records the peer's read pointer. Idempotent — only moves forward.
  Future<void> setOtherUserLastReadAt({
    required String chatId,
    required DateTime at,
  }) async {
    final existing = await getChat(chatId);
    if (existing == null) return;
    final current = existing.otherUserLastReadAt;
    if (current != null && !at.isAfter(current)) return;
    await (update(chats)..where((c) => c.chatId.equals(chatId)))
        .write(ChatsCompanion(
      otherUserLastReadAt: Value(at),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> bumpLastMessage({
    required String chatId,
    required String messageId,
    required DateTime at,
  }) async {
    await (update(chats)..where((c) => c.chatId.equals(chatId)))
        .write(ChatsCompanion(
      lastMessageId: Value(messageId),
      lastMessageAt: Value(at),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteChat(String chatId) async {
    await transaction(() async {
      await (delete(messages)..where((m) => m.chatId.equals(chatId))).go();
      await (delete(chats)..where((c) => c.chatId.equals(chatId))).go();
    });
  }

  Future<void> wipe() async {
    await transaction(() async {
      await delete(messages).go();
      await delete(chats).go();
      await delete(outboxRows).go();
      await delete(syncStateRows).go();
    });
  }

  // ─────────────────────────── Messages ────────────────────────────────

  Stream<List<Message>> watchMessagesForChat(String chatId) {
    return (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([
            (m) => OrderingTerm(expression: m.createdAt),
            (m) => OrderingTerm(expression: m.rowId),
          ]))
        .watch();
  }

  Future<Message?> getMessageByClientId(String clientId) {
    return (select(messages)..where((m) => m.clientId.equals(clientId)))
        .getSingleOrNull();
  }

  Future<Message?> getMessageById(String id) {
    return (select(messages)..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  /// Returns the timestamp of the most recent message in the given chat,
  /// or `null` if the chat has no messages yet. Used by the outbox to make
  /// sure new optimistic sends always sort at the visual bottom even when
  /// the server clock is ahead of the device clock.
  Future<DateTime?> getLatestMessageCreatedAt(String chatId) async {
    final row = await (select(messages)
          ..where((m) => m.chatId.equals(chatId))
          ..orderBy([
            (m) => OrderingTerm(
                  expression: m.createdAt,
                  mode: OrderingMode.desc,
                ),
            (m) => OrderingTerm(
                  expression: m.rowId,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row?.createdAt;
  }

  Future<void> upsertMessage(MessagesCompanion entry) async {
    final clientId = entry.clientId.value;
    final existing =
        await (select(messages)..where((m) => m.clientId.equals(clientId)))
            .getSingleOrNull();
    if (existing == null) {
      await into(messages).insert(entry);
    } else {
      await (update(messages)..where((m) => m.rowId.equals(existing.rowId)))
          .write(entry);
    }
  }

  Future<void> deleteMessageById(String id) async {
    await (delete(messages)..where((m) => m.id.equals(id))).go();
  }

  Future<void> markMessageStatus({
    required String clientId,
    required String status,
  }) async {
    await (update(messages)..where((m) => m.clientId.equals(clientId)))
        .write(MessagesCompanion(status: Value(status)));
  }

  // ─────────────────────────── Sync state ──────────────────────────────

  Future<String?> getCursor() async {
    final row = await (select(syncStateRows)
          ..where((s) => s.key.equals('global')))
        .getSingleOrNull();
    return row?.cursor;
  }

  Future<void> setCursor(String cursor) async {
    await into(syncStateRows).insertOnConflictUpdate(
      SyncStateRowsCompanion.insert(
        key: 'global',
        cursor: Value(cursor),
        lastSyncAt: Value(DateTime.now()),
      ),
    );
  }

  // ─────────────────────────── Outbox ──────────────────────────────────

  Stream<List<OutboxRow>> watchOutbox() => select(outboxRows).watch();

  Future<List<OutboxRow>> readyOutboxRows({DateTime? now}) async {
    final cutoff = now ?? DateTime.now();
    return (select(outboxRows)
          ..where((o) => o.nextAttemptAt.isNull() | o.nextAttemptAt.isSmallerOrEqualValue(cutoff))
          ..orderBy([(o) => OrderingTerm(expression: o.createdAt)]))
        .get();
  }

  Future<void> insertOutbox(OutboxRowsCompanion entry) async {
    await into(outboxRows).insert(entry);
  }

  Future<void> updateOutboxByClientId(
    String clientId,
    OutboxRowsCompanion entry,
  ) async {
    await (update(outboxRows)..where((o) => o.clientId.equals(clientId)))
        .write(entry);
  }

  Future<void> deleteOutboxByClientId(String clientId) async {
    await (delete(outboxRows)..where((o) => o.clientId.equals(clientId))).go();
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'skillder_chat');
}
