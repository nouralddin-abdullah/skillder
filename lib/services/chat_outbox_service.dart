import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/chat_models.dart';
import 'api_exception.dart';
import 'chat_repository.dart';
import 'chat_service.dart';
import 'media_uploader.dart';

const _uuid = Uuid();

/// Backoff schedule (seconds) for transient send failures. Stops retrying
/// once we exhaust the list — the outbox row stays around for the user to
/// manually re-tap (UI hook for that lands in stage 3).
const _retryDelays = <int>[2, 5, 10, 30, 60];

/// Manages the local send queue. Every chat-detail send goes through here
/// so that:
///  - The message appears instantly in the UI (writes to messages table
///    BEFORE the network call)
///  - Sends survive network drops (rows in [OutboxRows] are retried)
///  - Retries are idempotent on the server (same `clientId`)
class ChatOutboxService {
  final ChatRepository repository;

  /// Internal flag so [drain] can be called freely without overlapping work.
  bool _draining = false;

  /// Currently scheduled retry. Reset on every drain so backoffs collapse.
  Timer? _retryTimer;

  ChatOutboxService(this.repository);

  // ─────────────────────────── Public API ──────────────────────────────

  /// Queue a text message. Returns the `clientId` so callers can hold a
  /// reference to track it (rarely needed).
  Future<String> enqueueText({
    required String chatId,
    required String body,
    required String? senderId,
    String? replyToId,
  }) async {
    final clientId = _uuid.v4();
    final now = await _nextOptimisticCreatedAt(chatId);

    await repository.upsertMessage(MessageEntity(
      clientId: clientId,
      chatId: chatId,
      senderId: senderId,
      kind: MessageKind.text,
      body: body,
      replyToId: replyToId,
      createdAt: now,
      status: MessageStatus.sending,
    ));

    await repository.db.insertOutbox(OutboxRowsCompanion(
      clientId: Value(clientId),
      chatId: Value(chatId),
      kind: const Value('text'),
      body: Value(body),
      replyToId: Value(replyToId),
      createdAt: Value(now),
    ));

    // Don't await — the UI shouldn't block on the network round-trip.
    unawaited(drain());
    return clientId;
  }

  /// Queue an image message. Backend's whitelist of image MIMEs:
  /// jpeg, png, webp, gif, heic. We default to jpeg.
  Future<String> enqueueImage({
    required String chatId,
    required String? senderId,
    required Uint8List bytes,
    String? filePath,
    String? caption,
    String? replyToId,
    String filename = 'photo.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final clientId = _uuid.v4();
    final now = await _nextOptimisticCreatedAt(chatId);
    final captionOrNull =
        (caption != null && caption.trim().isNotEmpty) ? caption.trim() : null;

    await repository.upsertMessage(MessageEntity(
      clientId: clientId,
      chatId: chatId,
      senderId: senderId,
      kind: MessageKind.image,
      mediaCaption: captionOrNull,
      replyToId: replyToId,
      createdAt: now,
      status: MessageStatus.sending,
      localImageBytes: bytes,
    ));

    // Prefer the on-disk path on native — avoids loading the bytes into
    // SQLite as a BLOB. Bytes are kept only when no path is available
    // (web), and only for tiny payloads we'd already have in RAM.
    final preferPath = filePath != null;
    await repository.db.insertOutbox(OutboxRowsCompanion(
      clientId: Value(clientId),
      chatId: Value(chatId),
      kind: const Value('image'),
      mediaCaption: Value(captionOrNull),
      mediaLocalPath: Value(filePath),
      mediaLocalBytes: preferPath ? const Value(null) : Value(bytes),
      mediaFilename: Value(filename),
      mediaContentType: Value(contentType),
      replyToId: Value(replyToId),
      createdAt: Value(now),
    ));

    unawaited(drain());
    return clientId;
  }

  /// Queue a video message. The caller supplies one of:
  ///   - [videoFilePath] — on-disk path (native, preferred — streams from
  ///     disk during upload, no in-memory blob)
  ///   - [videoBytes] — only when there's no file path (web)
  /// Plus:
  ///   - [thumbnailBytes] (small JPEG, fits in RAM comfortably)
  ///   - probed metadata: width, height, duration in seconds
  ///
  /// Backend requires all five fields on the message create; partial
  /// uploads are rejected with 400.
  Future<String> enqueueVideo({
    required String chatId,
    required String? senderId,
    required Uint8List thumbnailBytes,
    required int width,
    required int height,
    required int durationSeconds,
    required String contentType, // e.g. video/mp4
    String? videoFilePath,
    Uint8List? videoBytes,
    String? caption,
    String? replyToId,
    String filename = 'video.mp4',
  }) async {
    assert(videoFilePath != null || videoBytes != null,
        'Need either filePath or bytes for the video');
    final clientId = _uuid.v4();
    final now = await _nextOptimisticCreatedAt(chatId);
    final captionOrNull =
        (caption != null && caption.trim().isNotEmpty) ? caption.trim() : null;

    // Use the thumbnail as the optimistic preview so the bubble renders
    // immediately while the (potentially huge) video uploads.
    await repository.upsertMessage(MessageEntity(
      clientId: clientId,
      chatId: chatId,
      senderId: senderId,
      kind: MessageKind.video,
      mediaCaption: captionOrNull,
      mediaWidth: width,
      mediaHeight: height,
      mediaDurationSeconds: durationSeconds,
      replyToId: replyToId,
      createdAt: now,
      status: MessageStatus.sending,
      localImageBytes: thumbnailBytes,
    ));

    final preferPath = videoFilePath != null;
    await repository.db.insertOutbox(OutboxRowsCompanion(
      clientId: Value(clientId),
      chatId: Value(chatId),
      kind: const Value('video'),
      mediaCaption: Value(captionOrNull),
      mediaLocalPath: Value(videoFilePath),
      mediaLocalBytes:
          preferPath ? const Value(null) : Value(videoBytes),
      mediaThumbnailLocalBytes: Value(thumbnailBytes),
      mediaFilename: Value(filename),
      mediaContentType: Value(contentType),
      mediaWidth: Value(width),
      mediaHeight: Value(height),
      mediaDurationSeconds: Value(durationSeconds),
      replyToId: Value(replyToId),
      createdAt: Value(now),
    ));

    unawaited(drain());
    return clientId;
  }

  /// Walk every outbox row whose `nextAttemptAt` is now-or-past and try to
  /// send it. Idempotent — safe to call from multiple sites.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (true) {
        final ready = await repository.db.readyOutboxRows();
        if (ready.isEmpty) break;
        for (final row in ready) {
          await _processOne(row);
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Uploads the media via the backend's sign + PUT flow if [existingUrl]
  /// is null. Prefers the file path on native (streams from disk, no
  /// memory pressure) and falls back to in-memory bytes when needed
  /// (web, or thumbnails that were generated as bytes). Persists the
  /// resulting public URL into the outbox row so a crash mid-flight
  /// doesn't trigger a re-upload.
  Future<String> _ensureUploaded({
    required OutboxRow row,
    required String contentType,
    required String? existingUrl,
    required _MediaUrlField urlField,
    String? filePath,
    Uint8List? bytes,
  }) async {
    if (existingUrl != null) return existingUrl;
    if (filePath == null && bytes == null) {
      throw StateError('Outbox row has no payload for ${urlField.name}');
    }
    final url = await MediaUploader.uploadAndSign(
      chatId: row.chatId,
      contentType: contentType,
      filePath: filePath,
      bytes: bytes,
    );
    final companion = switch (urlField) {
      _MediaUrlField.media => OutboxRowsCompanion(mediaUrl: Value(url)),
      _MediaUrlField.thumbnail =>
        OutboxRowsCompanion(mediaThumbnailUrl: Value(url)),
    };
    await repository.db.updateOutboxByClientId(row.clientId, companion);
    return url;
  }

  /// Returns a UTC timestamp that's guaranteed to be later than every other
  /// message currently in this chat. Without this, an optimistic send can
  /// look "older" than confirmed messages whose server-issued `createdAt`
  /// is slightly ahead of the device clock — and so render above them in
  /// the chronological list.
  Future<DateTime> _nextOptimisticCreatedAt(String chatId) async {
    final candidate = DateTime.now().toUtc();
    final latest = await repository.db.getLatestMessageCreatedAt(chatId);
    if (latest == null || candidate.isAfter(latest)) return candidate;
    return latest.add(const Duration(milliseconds: 1));
  }

  // ─────────────────────────── Internals ───────────────────────────────

  Future<void> _processOne(OutboxRow row) async {
    try {
      late MessageEntity confirmed;

      if (row.kind == 'text') {
        confirmed = await ChatService.sendText(
          chatId: row.chatId,
          clientId: row.clientId,
          body: row.body ?? '',
          replyToId: row.replyToId,
        );
      } else if (row.kind == 'image') {
        final mediaUrl = await _ensureUploaded(
          row: row,
          contentType: row.mediaContentType ?? 'image/jpeg',
          existingUrl: row.mediaUrl,
          urlField: _MediaUrlField.media,
          filePath: row.mediaLocalPath,
          bytes: row.mediaLocalBytes,
        );
        confirmed = await ChatService.sendImage(
          chatId: row.chatId,
          clientId: row.clientId,
          mediaUrl: mediaUrl,
          caption: row.mediaCaption,
          replyToId: row.replyToId,
        );
      } else if (row.kind == 'video') {
        // Need both video + thumbnail uploaded before we can call
        // POST /messages. Each is independently retryable thanks to the
        // persisted URL on success.
        final thumbBytes = row.mediaThumbnailLocalBytes;
        if (thumbBytes == null && row.mediaThumbnailUrl == null) {
          // Should never happen — enqueue ensures one of these is set.
          await repository.db.deleteOutboxByClientId(row.clientId);
          return;
        }
        // Stream the video straight from disk on native (avoids holding
        // a 100MB blob in RAM). Bytes path is the web fallback.
        final videoUrl = await _ensureUploaded(
          row: row,
          contentType: row.mediaContentType ?? 'video/mp4',
          existingUrl: row.mediaUrl,
          urlField: _MediaUrlField.media,
          filePath: row.mediaLocalPath,
          bytes: row.mediaLocalBytes,
        );
        final thumbnailUrl = await _ensureUploaded(
          row: row,
          contentType: 'image/jpeg',
          existingUrl: row.mediaThumbnailUrl,
          urlField: _MediaUrlField.thumbnail,
          bytes: thumbBytes,
        );
        confirmed = await ChatService.sendVideo(
          chatId: row.chatId,
          clientId: row.clientId,
          mediaUrl: videoUrl,
          mediaThumbnailUrl: thumbnailUrl,
          width: row.mediaWidth ?? 0,
          height: row.mediaHeight ?? 0,
          durationSeconds: row.mediaDurationSeconds ?? 0,
          caption: row.mediaCaption,
          replyToId: row.replyToId,
        );
      } else {
        // Unknown kind — drop it so the queue doesn't get stuck.
        await repository.db.deleteOutboxByClientId(row.clientId);
        return;
      }

      // Preserve the optimistic createdAt if it's later than the server's.
      // This protects against the bubble visually jumping backward when the
      // device clock is ahead of the server clock.
      final existing =
          await repository.db.getMessageByClientId(row.clientId);
      final preservedCreatedAt = existing != null &&
              existing.createdAt.isAfter(confirmed.createdAt)
          ? existing.createdAt
          : confirmed.createdAt;
      final adjusted = confirmed.copyWith(createdAt: preservedCreatedAt);

      await repository.upsertMessage(adjusted);
      final id = adjusted.id;
      if (id != null) {
        // Only bump the chat preview if this message is actually the newest.
        // When multiple confirms race in (we sent 5 messages quickly), we
        // don't want an earlier confirmation to overwrite the preview with
        // an older message body.
        final chat = await repository.getChat(adjusted.chatId);
        final keep = chat != null &&
            chat.lastMessage != null &&
            chat.lastMessage!.createdAt.isAfter(adjusted.createdAt);
        await repository.bumpChatForNewMessage(
          chatId: adjusted.chatId,
          messageId: id,
          at: adjusted.createdAt,
          incrementUnread: false, // own send
          keepCurrentLastMessage: keep,
        );
      }
      await repository.db.deleteOutboxByClientId(row.clientId);
    } on ApiException catch (e) {
      await _onFailure(row, '${e.statusCode}: ${e.message}', isPermanent: e.statusCode >= 400 && e.statusCode < 500 && e.statusCode != 408 && e.statusCode != 429);
    } catch (e) {
      await _onFailure(row, e.toString(), isPermanent: false);
    }
  }

  Future<void> _onFailure(
    OutboxRow row,
    String message, {
    required bool isPermanent,
  }) async {
    final attempts = row.attempts + 1;
    if (isPermanent || attempts > _retryDelays.length) {
      await repository.db.updateOutboxByClientId(
        row.clientId,
        OutboxRowsCompanion(
          attempts: Value(attempts),
          lastError: Value(message),
          nextAttemptAt: const Value(null),
        ),
      );
      await repository.markMessageStatus(
        clientId: row.clientId,
        status: MessageStatus.failed,
      );
      return;
    }
    final delay = _retryDelays[attempts - 1];
    final nextAt = DateTime.now().add(Duration(seconds: delay));
    await repository.db.updateOutboxByClientId(
      row.clientId,
      OutboxRowsCompanion(
        attempts: Value(attempts),
        lastError: Value(message),
        nextAttemptAt: Value(nextAt),
      ),
    );
    _scheduleRetry(delay);
  }

  void _scheduleRetry(int seconds) {
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), () {
      unawaited(drain());
    });
  }

  /// Manually retry every failed/queued item — UI can call this from a
  /// "Retry all" button (not yet wired).
  Future<void> retryNow() async {
    final all = await repository.db.select(repository.db.outboxRows).get();
    for (final r in all) {
      await repository.db.updateOutboxByClientId(
        r.clientId,
        const OutboxRowsCompanion(
          nextAttemptAt: Value(null),
          lastError: Value(null),
        ),
      );
    }
    unawaited(drain());
  }

  /// Tap-to-retry for a single failed message. Resets attempts/backoff,
  /// flips the message back to `sending`, and kicks the drain.
  Future<void> retry(String clientId) async {
    final row = await (repository.db.select(repository.db.outboxRows)
          ..where((o) => o.clientId.equals(clientId)))
        .getSingleOrNull();
    if (row == null) return;
    await repository.db.updateOutboxByClientId(
      clientId,
      const OutboxRowsCompanion(
        attempts: Value(0),
        nextAttemptAt: Value(null),
        lastError: Value(null),
      ),
    );
    await repository.markMessageStatus(
      clientId: clientId,
      status: MessageStatus.sending,
    );
    unawaited(drain());
  }
}

/// Which URL field on the outbox row a particular upload target maps to.
enum _MediaUrlField { media, thumbnail }

class ChatOutboxServiceHolder {
  static ChatOutboxService? _instance;

  static Future<ChatOutboxService> instance() async {
    final existing = _instance;
    if (existing != null) return existing;
    final repo = await ChatRepositoryHolder.instance();
    final created = ChatOutboxService(repo);
    _instance = created;
    return created;
  }

  static void reset() {
    _instance = null;
  }
}
