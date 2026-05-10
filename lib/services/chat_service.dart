import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'auth_storage.dart';

/// Thin REST wrapper for the `/chats` endpoints. Stage-1 layer: every call
/// goes straight to the server; no local cache yet (Drift comes in stage 2).
class ChatService {
  static Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final token = await AuthStorage.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────── List + history ───────────────────────────

  /// `GET /chats` — every chat the current user has, freshest first.
  static Future<List<ChatSummary>> listChats() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/chats'),
      headers: await _authHeaders(json: false),
    );
    final body = _decodeOrThrow(res, 'Failed to load chats');
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatSummary.fromJson)
        .toList();
  }

  /// `GET /chats/:chatId/messages?before=&limit=` — paginated history,
  /// newest first as returned by the server.
  static Future<List<MessageEntity>> getHistory(
    String chatId, {
    String? beforeMessageId,
    int limit = 50,
  }) async {
    final qp = <String, String>{'limit': '$limit'};
    if (beforeMessageId != null) qp['before'] = beforeMessageId;
    final uri = Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/messages')
        .replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _authHeaders(json: false));
    final body = _decodeOrThrow(res, 'Failed to load messages');
    final data = body['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MessageEntity.fromJson)
        .toList();
  }

  // ─────────────────────────── Send / edit / unsend ─────────────────────

  /// `POST /chats/:chatId/messages` — text message.
  ///
  /// Idempotent on `(chatId, clientId)`. Pass the same `clientId` on retry.
  static Future<MessageEntity> sendText({
    required String chatId,
    required String clientId,
    required String body,
    String? replyToId,
  }) {
    return _sendMessage(
      chatId: chatId,
      payload: {
        'clientId': clientId,
        'kind': 'text',
        'body': body,
        if (replyToId != null) 'replyToId': replyToId,
      },
    );
  }

  /// `POST /chats/:chatId/messages` — image message. Caller must have
  /// already uploaded the bytes via [signMedia] + [putToSignedUrl].
  static Future<MessageEntity> sendImage({
    required String chatId,
    required String clientId,
    required String mediaUrl,
    String? caption,
    String? replyToId,
  }) {
    return _sendMessage(
      chatId: chatId,
      payload: {
        'clientId': clientId,
        'kind': 'image',
        'mediaUrl': mediaUrl,
        if (caption != null && caption.isNotEmpty) 'mediaCaption': caption,
        if (replyToId != null) 'replyToId': replyToId,
      },
    );
  }

  /// `POST /chats/:chatId/messages` — video message. Backend requires the
  /// full metadata bundle: media URL + thumbnail URL + dimensions +
  /// duration. The Flutter side gets these by probing the local file
  /// before upload (via `video_player` for w/h/duration and
  /// `video_thumbnail` for the still frame).
  static Future<MessageEntity> sendVideo({
    required String chatId,
    required String clientId,
    required String mediaUrl,
    required String mediaThumbnailUrl,
    required int width,
    required int height,
    required int durationSeconds,
    String? caption,
    String? replyToId,
  }) {
    return _sendMessage(
      chatId: chatId,
      payload: {
        'clientId': clientId,
        'kind': 'video',
        'mediaUrl': mediaUrl,
        'mediaThumbnailUrl': mediaThumbnailUrl,
        'mediaWidth': width,
        'mediaHeight': height,
        'mediaDurationSeconds': durationSeconds,
        if (caption != null && caption.isNotEmpty) 'mediaCaption': caption,
        if (replyToId != null) 'replyToId': replyToId,
      },
    );
  }

  static Future<MessageEntity> _sendMessage({
    required String chatId,
    required Map<String, dynamic> payload,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/messages'),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );
    final body = _decodeOrThrow(res, 'Failed to send message');
    return MessageEntity.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// `PATCH /chats/:chatId/messages/:messageId` — edit body or caption.
  static Future<MessageEntity> editMessage({
    required String chatId,
    required String messageId,
    String? body,
    String? mediaCaption,
  }) async {
    if (body == null && mediaCaption == null) {
      throw ArgumentError('Provide body or mediaCaption to edit');
    }
    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/messages/$messageId'),
      headers: await _authHeaders(),
      body: jsonEncode({
        if (body != null) 'body': body,
        if (mediaCaption != null) 'mediaCaption': mediaCaption,
      }),
    );
    final responseBody = _decodeOrThrow(res, 'Failed to edit message');
    return MessageEntity.fromJson(
        responseBody['data'] as Map<String, dynamic>);
  }

  /// `DELETE /chats/:chatId/messages/:messageId` — unsend.
  static Future<MessageEntity> unsendMessage({
    required String chatId,
    required String messageId,
  }) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/messages/$messageId'),
      headers: await _authHeaders(json: false),
    );
    final body = _decodeOrThrow(res, 'Failed to unsend message');
    return MessageEntity.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────── Read receipt ─────────────────────────────

  /// `POST /chats/:chatId/read` — moves the last-read pointer up to the
  /// given message. 200 OK even if the chat is in a soft-removed state.
  static Future<void> markRead({
    required String chatId,
    required String upToMessageId,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/read'),
      headers: await _authHeaders(),
      body: jsonEncode({'upToMessageId': upToMessageId}),
    );
    _decodeOrThrow(res, 'Failed to mark as read');
  }

  // ─────────────────────────── Media upload ─────────────────────────────

  /// `POST /chats/:chatId/media/sign` — asks the backend for a presigned
  /// PUT URL to upload directly to R2.
  ///
  /// [contentType] must match one of the backend's whitelisted MIMEs
  /// (image/jpeg, image/png, image/webp, image/gif, image/heic,
  /// video/mp4, video/quicktime, video/webm). [size] must equal the
  /// exact byte length the client will PUT — backend binds it to the
  /// presigned URL so a client can't smuggle larger files.
  static Future<MediaUploadResult> signMedia({
    required String chatId,
    required String contentType,
    required int size,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/media/sign'),
      headers: await _authHeaders(),
      body: jsonEncode({'contentType': contentType, 'size': size}),
    );
    final body = _decodeOrThrow(res, 'Failed to sign media upload');
    return MediaUploadResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// `PUT <presigned R2 URL>` — uploads the bytes directly to storage.
  /// The presigned URL is bound to a specific Content-Type and
  /// Content-Length, both of which we set here.
  static Future<void> putToSignedUrl({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
        'Content-Length': bytes.length.toString(),
      },
      body: bytes,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Direct upload failed (${res.statusCode})',
      );
    }
  }

  /// Convenience: signs, uploads, and returns the public `mediaUrl` in
  /// one call. Most callers should prefer this.
  static Future<String> uploadMedia({
    required String chatId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final signed = await signMedia(
      chatId: chatId,
      contentType: contentType,
      size: bytes.length,
    );
    await putToSignedUrl(
      uploadUrl: signed.uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );
    return signed.mediaUrl;
  }

  // ─────────────────────────── Helpers ──────────────────────────────────

  /// MIME type from a filename. Limited to the backend's whitelist —
  /// returns `null` for anything not allowed.
  static String? mimeFromFilename(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
      case 'qt':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return null;
    }
  }
}

/// Decode JSON, raise [ApiException] on non-2xx. Centralized so all chat
/// endpoints surface failures in one consistent shape.
Map<String, dynamic> _decodeOrThrow(http.Response res, String fallback) {
  Map<String, dynamic>? body;
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) body = decoded;
  } catch (_) {}
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(
      statusCode: res.statusCode,
      message: body?['message']?.toString() ?? fallback,
    );
  }
  return body ?? const {};
}
