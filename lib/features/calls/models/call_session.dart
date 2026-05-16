import 'call_models.dart';

/// Local UI state of a call from this device's POV. The backend's
/// [CallStatus] tracks server truth; this enum tracks the client lifecycle
/// including the brief states that don't exist on the server (e.g. we're
/// dialing the API but haven't gotten a callId back yet).
enum LocalCallPhase {
  /// API call to POST /calls in flight; no callId yet.
  dialing,

  /// We are the caller, ringing on the peer's device, waiting for accept.
  outgoing,

  /// We are the callee, the FCM/socket event arrived, we're showing the
  /// incoming-call UI to the user.
  incoming,

  /// User tapped Accept — POST /accept is in flight. A transitional phase
  /// so a second tap doesn't kick off a parallel accept.
  accepting,

  /// REST handshake is done (callee) or peer accepted (caller). LiveKit
  /// room.connect + track publish is in progress. UI should show
  /// "Connecting…" — the local mic/camera flags are still false here so
  /// we deliberately don't render the control row to avoid showing a
  /// misleading "muted mic" icon during the 1-3 second handshake.
  connecting,

  /// Both sides connected to LiveKit; voice/video flowing.
  active,

  /// LiveKit dropped temporarily, attempting recover.
  reconnecting,

  /// Call is over (any reason). UI returns to wherever it was.
  ended,
}

/// In-flight call data — survives across screens via the app-root controller.
/// Distinct from [CallRecord] (which is the server's view) because this also
/// holds local-only state (peer display, mic/cam toggles, etc.).
class CallSession {
  /// Server-issued ID. Null only during the brief [LocalCallPhase.dialing]
  /// window before POST /calls returns.
  final String? callId;

  final String chatId;

  /// Other party's user id, name, photo. For incoming calls these are
  /// resolved from the FCM payload (cold start) or the chat object (warm).
  final String peerUserId;
  final String peerName;
  final String? peerPhotoUrl;

  final CallKind kind;
  final LocalCallPhase phase;

  /// LiveKit room name (`call-{callId}`). Set after the initial REST call.
  final String? roomName;

  /// LiveKit JWT — caller's on initiate, callee's on accept.
  final String? livekitToken;

  /// LiveKit server URL.
  final String? livekitUrl;

  /// True if WE initiated this call (caller). Drives UI subtleties like
  /// which tone plays (ringback vs ringtone) and whether the cancel button
  /// shows during ringing.
  final bool initiatedByMe;

  final DateTime startedAt;
  final DateTime? answeredAt;

  /// When the ring should auto-cancel client-side as a safety net even if
  /// no server event arrives. Comes from `expiresAt` on `call.incoming` or
  /// is computed as `startedAt + 45s` on the caller side.
  final DateTime ringExpiresAt;

  const CallSession({
    required this.chatId,
    required this.peerUserId,
    required this.peerName,
    required this.peerPhotoUrl,
    required this.kind,
    required this.phase,
    required this.initiatedByMe,
    required this.startedAt,
    required this.ringExpiresAt,
    this.callId,
    this.roomName,
    this.livekitToken,
    this.livekitUrl,
    this.answeredAt,
  });

  CallSession copyWith({
    String? callId,
    LocalCallPhase? phase,
    String? roomName,
    String? livekitToken,
    String? livekitUrl,
    DateTime? answeredAt,
    String? peerName,
    String? peerPhotoUrl,
  }) {
    return CallSession(
      callId: callId ?? this.callId,
      chatId: chatId,
      peerUserId: peerUserId,
      peerName: peerName ?? this.peerName,
      peerPhotoUrl: peerPhotoUrl ?? this.peerPhotoUrl,
      kind: kind,
      phase: phase ?? this.phase,
      initiatedByMe: initiatedByMe,
      startedAt: startedAt,
      ringExpiresAt: ringExpiresAt,
      roomName: roomName ?? this.roomName,
      livekitToken: livekitToken ?? this.livekitToken,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}

/// Marker base class for incoming Socket.IO call events. Each concrete
/// subtype maps to one event name (`call.incoming`, `call.accepted`, etc.)
/// — see [parseCallEvent] for the wire-shape details.
sealed class CallEvent {
  final String callId;
  const CallEvent({required this.callId});
}

class CallIncomingEvent extends CallEvent {
  final String chatId;
  final String callerId;
  final CallKind kind;
  final DateTime startedAt;
  final DateTime expiresAt;
  const CallIncomingEvent({
    required super.callId,
    required this.chatId,
    required this.callerId,
    required this.kind,
    required this.startedAt,
    required this.expiresAt,
  });
}

class CallAcceptedEvent extends CallEvent {
  final DateTime answeredAt;
  const CallAcceptedEvent({required super.callId, required this.answeredAt});
}

class CallRejectedEvent extends CallEvent {
  const CallRejectedEvent({required super.callId});
}

class CallCancelledEvent extends CallEvent {
  const CallCancelledEvent({required super.callId});
}

class CallEndedEvent extends CallEvent {
  final DateTime endedAt;
  final int durationSeconds;
  final CallEndReason reason;
  const CallEndedEvent({
    required super.callId,
    required this.endedAt,
    required this.durationSeconds,
    required this.reason,
  });
}

/// One entry in a `call.snapshot` payload — represents one of the user's
/// currently-ringing or currently-active calls, as known to the server at
/// the moment of WS connect. Used for cold-boot / reconnect state recovery
/// per CALLS_FRONTEND_CONTRACT.md §2.
///
/// `livekitToken` is **freshly minted** by the server for this snapshot —
/// always prefer this token over any token cached on the client from a
/// previous `POST /api/calls` or `POST /accept` response.
class CallSnapshotEntry {
  final String callId;

  /// `'ringing'` or `'active'`. Never `ended` / `missed` / etc. — the
  /// server only includes live calls in the snapshot.
  final CallStatus status;

  /// `'caller'` if THIS user initiated, `'callee'` if they received it.
  /// Drives whether to show the outgoing-ring or incoming-ring UI when
  /// `status == 'ringing'`.
  final String role;

  final String chatId;
  final CallKind kind;
  final String roomName;
  final String livekitUrl;
  final String livekitToken;
  final String peerId;
  final String? peerName;
  final String? peerPhotoUrl;
  final DateTime startedAt;

  /// Set when `status == 'active'` (i.e. callee has accepted). `null` for
  /// `ringing` entries.
  final DateTime? answeredAt;

  /// Set when `status == 'ringing'` — ISO timestamp when the ring auto-
  /// expires server-side (~45s after `startedAt`). `null` for `active`.
  final DateTime? expiresAt;

  /// Set when `status == 'active'` — seconds since `answeredAt` at the
  /// moment the snapshot was generated. Useful as the initial offset for
  /// the in-call duration timer on resume.
  final int? durationSecondsSoFar;

  const CallSnapshotEntry({
    required this.callId,
    required this.status,
    required this.role,
    required this.chatId,
    required this.kind,
    required this.roomName,
    required this.livekitUrl,
    required this.livekitToken,
    required this.peerId,
    required this.peerName,
    required this.peerPhotoUrl,
    required this.startedAt,
    required this.answeredAt,
    required this.expiresAt,
    required this.durationSecondsSoFar,
  });

  factory CallSnapshotEntry.fromJson(Map<String, dynamic> json) {
    return CallSnapshotEntry(
      callId: json['callId'] as String,
      status: parseCallStatus(json['status']),
      role: json['role'] as String,
      chatId: json['chatId'] as String,
      kind: parseCallKind(json['kind']),
      roomName: json['roomName'] as String,
      livekitUrl: json['livekitUrl'] as String,
      livekitToken: json['livekitToken'] as String,
      peerId: json['peerId'] as String,
      peerName: json['peerName'] as String?,
      peerPhotoUrl: () {
        // Backend may send '' or null when there's no photo. Normalize.
        final raw = json['peerPhotoUrl'];
        if (raw is String && raw.isNotEmpty) return raw;
        return null;
      }(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      answeredAt: _parseDateOrNull(json['answeredAt']),
      expiresAt: _parseDateOrNull(json['expiresAt']),
      durationSecondsSoFar: (json['durationSecondsSoFar'] as num?)?.toInt(),
    );
  }
}

/// The `call.snapshot` socket.io event. Fires once on every WS connect.
///
/// Envelope shape (NOT the standard `{type, seq, chatId, data}` wrapper used
/// by per-call events): `{ type: 'call.snapshot', calls: [...] }`. An empty
/// `calls` array is the authoritative "you have no live calls" signal —
/// callers should clear any stale local ringing/active session.
class CallSnapshotEvent {
  final List<CallSnapshotEntry> calls;
  const CallSnapshotEvent({required this.calls});

  factory CallSnapshotEvent.fromJson(Map<String, dynamic> raw) {
    final list = raw['calls'];
    if (list is! List) return const CallSnapshotEvent(calls: []);
    return CallSnapshotEvent(
      calls: list
          .whereType<Map>()
          .map((m) => CallSnapshotEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false),
    );
  }
}

DateTime? _parseDateOrNull(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

/// Parses one Socket.IO event into a typed [CallEvent], or returns null if
/// the wrapper isn't a call event we handle.
///
/// Wire shape (per CALLS_CONTRACT_ACTUAL.md §2):
/// `{type, seq, chatId, data: {...}, createdAt}`
CallEvent? parseCallEvent(Map<String, dynamic> envelope) {
  final type = envelope['type']?.toString();
  final data = envelope['data'];
  if (type == null || data is! Map) return null;
  final d = Map<String, dynamic>.from(data);
  final callId = d['callId']?.toString();
  if (callId == null) return null;

  switch (type) {
    case 'call.incoming':
      return CallIncomingEvent(
        callId: callId,
        chatId: (d['chatId'] ?? envelope['chatId']) as String,
        callerId: d['callerId'] as String,
        kind: parseCallKind(d['kind']),
        startedAt: DateTime.parse(d['startedAt'] as String),
        expiresAt: DateTime.parse(d['expiresAt'] as String),
      );
    case 'call.accepted':
      return CallAcceptedEvent(
        callId: callId,
        answeredAt: DateTime.parse(d['answeredAt'] as String),
      );
    case 'call.rejected':
      return CallRejectedEvent(callId: callId);
    case 'call.cancelled':
      return CallCancelledEvent(callId: callId);
    case 'call.ended':
      return CallEndedEvent(
        callId: callId,
        endedAt: DateTime.parse(d['endedAt'] as String),
        durationSeconds: (d['durationSeconds'] as num?)?.toInt() ?? 0,
        reason: parseCallEndReason(d['reason']),
      );
    default:
      return null;
  }
}
