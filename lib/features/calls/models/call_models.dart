/// Typed entities for the calls feature. Mirrors the actual backend wire
/// format documented in CALLS_CONTRACT_ACTUAL.md.
///
/// Two key things to remember when reading this file:
/// 1. REST responses are wrapped `{success, message, data}` — Flutter unwraps
///    `.data` before constructing these.
/// 2. Socket.IO events arrive as `{type, seq, chatId, data, createdAt}` —
///    the call-specific fields live inside `data`.
library;

enum CallKind { voice, video }

CallKind parseCallKind(dynamic raw) {
  switch (raw) {
    case 'voice':
      return CallKind.voice;
    case 'video':
      return CallKind.video;
    default:
      throw ArgumentError('Unknown call kind: $raw');
  }
}

String callKindToWire(CallKind kind) =>
    kind == CallKind.voice ? 'voice' : 'video';

enum CallStatus { ringing, active, ended, missed, rejected, cancelled }

CallStatus parseCallStatus(dynamic raw) {
  switch (raw) {
    case 'ringing':
      return CallStatus.ringing;
    case 'active':
      return CallStatus.active;
    case 'ended':
      return CallStatus.ended;
    case 'missed':
      return CallStatus.missed;
    case 'rejected':
      return CallStatus.rejected;
    case 'cancelled':
      return CallStatus.cancelled;
    default:
      throw ArgumentError('Unknown call status: $raw');
  }
}

/// Mirrors backend's CallEndReason enum. Includes LiveKit webhook-derived
/// values that only fire from the server (we don't generate them client-side).
enum CallEndReason {
  normal,
  rejected,
  missed,
  cancelled,
  network,
  cellularInterrupt,
  participantDisconnected,
  roomFinishedInactive,
  busy,
  unknown,
}

CallEndReason parseCallEndReason(dynamic raw) {
  switch (raw) {
    case 'normal':
      return CallEndReason.normal;
    case 'rejected':
      return CallEndReason.rejected;
    case 'missed':
      return CallEndReason.missed;
    case 'cancelled':
      return CallEndReason.cancelled;
    case 'network':
      return CallEndReason.network;
    case 'cellular_interrupt':
      return CallEndReason.cellularInterrupt;
    case 'participant_disconnected':
      return CallEndReason.participantDisconnected;
    case 'room_finished_inactive':
      return CallEndReason.roomFinishedInactive;
    case 'busy':
      return CallEndReason.busy;
    default:
      return CallEndReason.unknown;
  }
}

String callEndReasonToWire(CallEndReason reason) {
  switch (reason) {
    case CallEndReason.normal:
      return 'normal';
    case CallEndReason.network:
      return 'network';
    case CallEndReason.cellularInterrupt:
      return 'cellular_interrupt';
    // The remaining values are server-set; we never POST them. Map to
    // 'normal' so a malformed end call still reaches the backend.
    default:
      return 'normal';
  }
}

/// Result of `POST /api/calls` (caller side) and `POST /api/calls/:id/accept`
/// (callee side). Identical shape; the JWT field is named `callerToken` vs
/// `calleeToken` in the wire response — we normalize to [token].
class CallConnection {
  final String callId;
  final String roomName;
  final String livekitUrl;
  final String token;

  /// True when this response was served from the backend's idempotency cache
  /// — i.e. a previous attempt with the same `Idempotency-Key` already
  /// produced this exact result. The token and callId are still valid; the
  /// controller must NOT start a second ringing UI when this is set.
  final bool idempotentReplay;

  const CallConnection({
    required this.callId,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    this.idempotentReplay = false,
  });

  factory CallConnection.fromJson(Map<String, dynamic> json) {
    final token = (json['callerToken'] ?? json['calleeToken']) as String?;
    if (token == null) {
      throw ArgumentError(
        'CallConnection: response missing callerToken/calleeToken',
      );
    }
    return CallConnection(
      callId: json['callId'] as String,
      roomName: json['roomName'] as String,
      livekitUrl: json['livekitUrl'] as String,
      token: token,
      // Only present on the second+ response for a given Idempotency-Key.
      // Absent on fresh 201s; default to false in that case.
      idempotentReplay: json['idempotentReplay'] == true,
    );
  }
}

/// Payload inside a 409 response's `body.message.existing` — describes the
/// call that's already in flight for the requesting user (or the callee).
/// Used so the UI can show "you're already on a call with X" or offer to
/// re-open the existing session.
class ExistingCallInfo {
  final String callId;
  final CallStatus status;

  /// The requesting user's role in the existing call. `'caller'` means the
  /// user is the one ringing; `'callee'` means the user is being rung.
  final String role;

  final String chatId;
  final String peerId;
  final String? peerName;
  final String? peerPhotoUrl;
  final CallKind kind;
  final DateTime startedAt;

  /// Seconds elapsed since the existing call's `startedAt`, as computed by
  /// the server at the moment it returned the 409. Used to decide whether
  /// a `caller_busy` should be retried (stale ring within the 5s grace
  /// window where the backend may auto-cancel and accept the new call).
  final int ageSeconds;

  const ExistingCallInfo({
    required this.callId,
    required this.status,
    required this.role,
    required this.chatId,
    required this.peerId,
    required this.peerName,
    required this.peerPhotoUrl,
    required this.kind,
    required this.startedAt,
    required this.ageSeconds,
  });

  factory ExistingCallInfo.fromJson(Map<String, dynamic> json) {
    return ExistingCallInfo(
      callId: json['callId'] as String,
      status: parseCallStatus(json['status']),
      role: json['role'] as String,
      chatId: json['chatId'] as String,
      peerId: json['peerId'] as String,
      peerName: json['peerName'] as String?,
      peerPhotoUrl: () {
        // Backend may send '' or null when there's no photo. Normalize to null.
        final raw = json['peerPhotoUrl'];
        if (raw is String && raw.isNotEmpty) return raw;
        return null;
      }(),
      kind: parseCallKind(json['kind']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      ageSeconds: (json['ageSeconds'] as num).toInt(),
    );
  }
}

/// Mirrors backend's `CallDTO` (returned by `GET /api/calls/:id`). Used for
/// reconciliation when the client missed events.
class CallRecord {
  final String id;
  final String chatId;
  final String callerId;
  final String calleeId;
  final CallKind kind;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final CallEndReason? endReason;

  const CallRecord({
    required this.id,
    required this.chatId,
    required this.callerId,
    required this.calleeId,
    required this.kind,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds,
    this.endReason,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      callerId: json['callerId'] as String,
      calleeId: json['calleeId'] as String,
      kind: parseCallKind(json['kind']),
      status: parseCallStatus(json['status']),
      startedAt: DateTime.parse(json['startedAt'] as String),
      answeredAt: _parseDate(json['answeredAt']),
      endedAt: _parseDate(json['endedAt']),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      endReason: json['endReason'] != null
          ? parseCallEndReason(json['endReason'])
          : null,
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
