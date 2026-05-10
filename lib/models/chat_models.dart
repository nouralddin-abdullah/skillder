/// Typed entities mirroring the backend chat DTOs.
///
/// One-way mapping: server JSON → Dart objects. We never serialize these back
/// to the server (sends use plain Maps in [ChatService.sendMessage]).
library;

import 'dart:typed_data';

enum MessageKind { text, image, video, system, unknown }

MessageKind parseMessageKind(dynamic raw) {
  switch (raw) {
    case 'text':
      return MessageKind.text;
    case 'image':
      return MessageKind.image;
    case 'video':
      return MessageKind.video;
    case 'system':
      return MessageKind.system;
    default:
      return MessageKind.unknown;
  }
}

/// Status of a message in the local UI lifecycle. Server-confirmed messages
/// are always [MessageStatus.sent]. The other states only apply to messages
/// the current user is actively sending.
enum MessageStatus { sending, sent, failed }

/// A message as the client sees it. Combines the server-shaped fields with a
/// few local-only ones used during optimistic sends.
class MessageEntity {
  /// Server-assigned UUID. Null while a send is in flight (use [clientId]).
  final String? id;

  /// Client-generated UUID, set at send time. Used for idempotent retries
  /// and to match an in-flight send to its server-confirmed result.
  final String clientId;

  final String chatId;

  /// Null for system messages (matched announcement, etc.).
  final String? senderId;

  final MessageKind kind;
  final String? body;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaCaption;
  final int? mediaWidth;
  final int? mediaHeight;
  final int? mediaDurationSeconds;
  final String? replyToId;

  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;

  /// Local UI status. [MessageStatus.sent] for anything from the server.
  final MessageStatus status;

  /// Local-only image bytes shown while an upload is still uploading. Once
  /// the message is confirmed by the server, [mediaUrl] takes over.
  final Uint8List? localImageBytes;

  const MessageEntity({
    required this.clientId,
    required this.chatId,
    required this.kind,
    required this.createdAt,
    required this.status,
    this.id,
    this.senderId,
    this.body,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaCaption,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaDurationSeconds,
    this.replyToId,
    this.editedAt,
    this.deletedAt,
    this.localImageBytes,
  });

  bool get isSystem => kind == MessageKind.system;
  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool get hasImage => kind == MessageKind.image;
  bool get hasVideo => kind == MessageKind.video;
  bool get hasMedia => hasImage || hasVideo;

  bool sentByMe(String? currentUserId) =>
      senderId != null && senderId == currentUserId;

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      id: json['id'] as String?,
      clientId: (json['clientId'] as String?) ?? '',
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String?,
      kind: parseMessageKind(json['kind']),
      body: json['body'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaThumbnailUrl: json['mediaThumbnailUrl'] as String?,
      mediaCaption: json['mediaCaption'] as String?,
      mediaWidth: (json['mediaWidth'] as num?)?.toInt(),
      mediaHeight: (json['mediaHeight'] as num?)?.toInt(),
      mediaDurationSeconds: (json['mediaDurationSeconds'] as num?)?.toInt(),
      replyToId: json['replyToId'] as String?,
      editedAt: _parseDate(json['editedAt']),
      deletedAt: _parseDate(json['deletedAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      status: MessageStatus.sent,
    );
  }

  MessageEntity copyWith({
    String? id,
    String? body,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? mediaCaption,
    int? mediaWidth,
    int? mediaHeight,
    int? mediaDurationSeconds,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    MessageStatus? status,
    Uint8List? localImageBytes,
    bool clearLocalImageBytes = false,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      clientId: clientId,
      chatId: chatId,
      senderId: senderId,
      kind: kind,
      body: body ?? this.body,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaCaption: mediaCaption ?? this.mediaCaption,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      mediaDurationSeconds:
          mediaDurationSeconds ?? this.mediaDurationSeconds,
      replyToId: replyToId,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      localImageBytes:
          clearLocalImageBytes ? null : (localImageBytes ?? this.localImageBytes),
    );
  }
}

/// Minimal slice of the other participant — exactly what the chat list +
/// chat header need to render. Backend returns a full PublicUserDTO; we keep
/// a typed projection so the UI never has to care.
class ChatOtherUser {
  final String id;
  final String name;
  final String? photoUrl;

  const ChatOtherUser({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  factory ChatOtherUser.fromJson(Map<String, dynamic> json) {
    final photos = json['photos'];
    String? photoUrl;
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first;
      if (first is Map<String, dynamic>) {
        photoUrl = first['url'] as String?;
      } else if (first is String) {
        photoUrl = first;
      }
    }
    return ChatOtherUser(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      photoUrl: photoUrl,
    );
  }
}

class ChatSummary {
  final String chatId;
  final String matchId;
  final ChatOtherUser otherUser;
  final MessageEntity? lastMessage;
  final int unreadCount;
  final DateTime? lastReadAt;

  /// The other party's last-read timestamp. Used to render ✓ vs ✓✓ on
  /// outgoing messages. Null until the first `message.read` event from
  /// the peer arrives via the socket / sync delta.
  final DateTime? otherUserLastReadAt;

  final bool removedByMe;

  const ChatSummary({
    required this.chatId,
    required this.matchId,
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
    required this.removedByMe,
    this.lastReadAt,
    this.otherUserLastReadAt,
  });

  /// True when this chat has no real conversation yet — only the system
  /// "You matched" message (or no message at all). Used by the chat list to
  /// show the avatar in the "New Matches" carousel.
  bool get isNewMatch =>
      lastMessage == null || lastMessage!.kind == MessageKind.system;

  bool get isUnread => unreadCount > 0;

  factory ChatSummary.fromJson(Map<String, dynamic> json) {
    final lm = json['lastMessage'];
    return ChatSummary(
      chatId: json['chatId'] as String,
      matchId: json['matchId'] as String,
      otherUser:
          ChatOtherUser.fromJson(json['otherUser'] as Map<String, dynamic>),
      lastMessage: lm is Map<String, dynamic> ? MessageEntity.fromJson(lm) : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      lastReadAt: _parseDate(json['lastReadAt']),
      removedByMe: json['removedByMe'] == true,
    );
  }

  ChatSummary copyWith({
    MessageEntity? lastMessage,
    int? unreadCount,
    DateTime? lastReadAt,
    DateTime? otherUserLastReadAt,
    bool? removedByMe,
  }) {
    return ChatSummary(
      chatId: chatId,
      matchId: matchId,
      otherUser: otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      otherUserLastReadAt:
          otherUserLastReadAt ?? this.otherUserLastReadAt,
      removedByMe: removedByMe ?? this.removedByMe,
    );
  }
}

/// Returned by `POST /chats/:id/media/sign`. The client PUTs the raw
/// bytes to [uploadUrl], then references [mediaUrl] when sending the
/// message that points at the uploaded file.
class MediaUploadResult {
  final String uploadUrl;
  final String mediaUrl;
  final String key;
  final int expiresInSeconds;

  const MediaUploadResult({
    required this.uploadUrl,
    required this.mediaUrl,
    required this.key,
    required this.expiresInSeconds,
  });

  factory MediaUploadResult.fromJson(Map<String, dynamic> json) =>
      MediaUploadResult(
        uploadUrl: json['uploadUrl'] as String,
        mediaUrl: json['mediaUrl'] as String,
        key: json['key'] as String,
        expiresInSeconds:
            (json['expiresInSeconds'] as num?)?.toInt() ?? 600,
      );
}

/// Returned by `POST /likes`.
class LikeResult {
  final bool liked;
  final bool matched;
  final String? matchId;
  final String? chatId;

  const LikeResult({
    required this.liked,
    required this.matched,
    this.matchId,
    this.chatId,
  });

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    return LikeResult(
      liked: json['liked'] == true,
      matched: json['matched'] == true,
      matchId: json['matchId'] as String?,
      chatId: json['chatId'] as String?,
    );
  }
}

class MatchSummary {
  final String matchId;
  final String chatId;
  final DateTime matchedAt;
  final bool removedByMe;
  final ChatOtherUser otherUser;

  const MatchSummary({
    required this.matchId,
    required this.chatId,
    required this.matchedAt,
    required this.removedByMe,
    required this.otherUser,
  });

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      matchId: json['matchId'] as String,
      chatId: json['chatId'] as String,
      matchedAt: _parseDate(json['matchedAt']) ?? DateTime.now().toUtc(),
      removedByMe: json['removedByMe'] == true,
      otherUser:
          ChatOtherUser.fromJson(json['otherUser'] as Map<String, dynamic>),
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
