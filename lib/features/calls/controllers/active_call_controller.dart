import 'dart:async';

import 'package:flutter/foundation.dart';
// Only the `FlutterCallkitIncoming` facade is used now — for `endCall`
// cleanup of cold-start incoming calls (set up by `showCallkitIncoming`
// in call_fcm_handler.dart). We no longer call `startCall` because we run
// our own foreground service via `CallAudioFgChannel`; calling both would
// produce duplicate ongoing-call notifications.
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

import '../../../services/auth_storage.dart';
import '../../../services/chat_repository.dart';
import '../../../services/chat_socket_service.dart';
import '../models/call_models.dart';
import '../models/call_session.dart';
import '../services/call_audio_fg_channel.dart';
import '../services/call_permissions.dart';
import '../services/call_service.dart';
import '../services/livekit_room_manager.dart';

/// App-root singleton that owns the single in-flight call (if any) and
/// exposes its state to the UI. Every screen shows / minimizes / hides
/// itself based on this controller's value.
///
/// Responsibilities:
///  - Drive the local call state machine (dialing → outgoing → active → ended)
///  - Wrap the REST calls in [CallService] and the LiveKit room in
///    [LiveKitRoomManager]
///  - Subscribe to socket call events and reconcile with local state,
///    including multi-device dismissal (F1 in CALLS_PLAN v2)
///  - Schedule client-side safety timers for ring expiry
class ActiveCallController extends ChangeNotifier {
  final ChatSocketService _socket;
  final LiveKitRoomManager _room;

  CallSession? _session;
  String? _currentUserId;

  StreamSubscription<CallEvent>? _eventsSub;
  StreamSubscription<CallSnapshotEvent>? _snapshotSub;
  StreamSubscription<RoomManagerEvent>? _roomSub;
  StreamSubscription<LocalTrackState>? _localSub;
  Timer? _ringExpiryTimer;

  /// Broadcast stream of human-readable error messages produced by the
  /// controller. A top-level widget subscribes and shows a SnackBar — this
  /// is the only path the user has to learn that a silent failure (e.g.
  /// LiveKit ICE timeout, REST rejection) ended their call.
  final StreamController<String> _errorEvents =
      StreamController<String>.broadcast();
  Stream<String> get errorEvents => _errorEvents.stream;

  /// Whether the active-call screen is currently maximised. False means the
  /// minibar should be visible across other screens.
  bool _maximised = true;

  /// In-flight guard for [initiate]. Prevents a second tap of the call button
  /// (or a sibling code path) from racing a parallel `POST /api/calls` while
  /// the first attempt is still mid-handshake — the original 8-retries-in-
  /// 2.4s storm. The button's visual disabled state is driven off this.
  bool _initiateInFlight = false;
  bool get isInitiating => _initiateInFlight;

  ActiveCallController({
    required ChatSocketService socket,
    LiveKitRoomManager? room,
  })  : _socket = socket,
        _room = room ?? LiveKitRoomManager() {
    _eventsSub = _socket.callEventStream.listen(_onSocketEvent);
    _snapshotSub = _socket.callSnapshotStream.listen(_onSnapshot);
    _roomSub = _room.events.listen(_onRoomEvent);
    _localSub = _room.localTrackState.listen((_) => notifyListeners());
    unawaited(_loadCurrentUserId());
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await AuthStorage.getUserId();
  }

  // ─────────────────────────── Public state ────────────────────────────

  CallSession? get session => _session;
  bool get hasActiveCall => _session != null;
  bool get isMaximised => _maximised;
  LocalTrackState get localTracks => _room.currentLocal;
  LiveKitRoomManager get room => _room;

  void setMaximised(bool value) {
    if (_maximised == value) return;
    _maximised = value;
    notifyListeners();
  }

  // ─────────────────────────── Outbound actions ────────────────────────

  /// Caller-side: kick off a new call to [peer] in [chatId]. Throws if
  /// there's already a call in flight on this device, or surfaces a typed
  /// exception when the server reports a busy state.
  ///
  /// In-flight semantics: a second invocation while the first is still
  /// resolving returns immediately as a no-op (rather than throwing) so a
  /// rebuild-driven double-tap doesn't surface a confusing error.
  ///
  /// Idempotency: we generate one UUID v4 per **user-initiated attempt** and
  /// pass it as `Idempotency-Key` so the backend can replay the response on
  /// internal retries — see CALLS_FRONTEND_CONTRACT.md §2.1. If the server
  /// returns `caller_busy` for a stale own-ring younger than 5s, we wait 1s
  /// and retry **with the same key** (the backend's stale-ring auto-cancel
  /// may have completed in the meantime).
  Future<void> initiate({
    required String chatId,
    required String peerUserId,
    required String peerName,
    String? peerPhotoUrl,
    required CallKind kind,
  }) async {
    if (_initiateInFlight) {
      // Second tap while we're still mid-handshake — silently no-op rather
      // than surfacing "A call is already in progress" from the StateError
      // branch below, because the user's intent ("call this peer") is being
      // honored by the original attempt.
      return;
    }
    if (_session != null) {
      throw StateError('A call is already in progress');
    }
    _currentUserId ??= await AuthStorage.getUserId();

    // Without runtime mic (and camera for video) the WebRTC publish silently
    // no-ops on most Android OEMs. Fail fast with a typed error the UI can
    // turn into a snackbar.
    await CallPermissions.ensureForCall(kind);

    _initiateInFlight = true;
    final idempotencyKey = const Uuid().v4();

    final now = DateTime.now().toUtc();
    _session = CallSession(
      chatId: chatId,
      peerUserId: peerUserId,
      peerName: peerName,
      peerPhotoUrl: peerPhotoUrl,
      kind: kind,
      phase: LocalCallPhase.dialing,
      initiatedByMe: true,
      startedAt: now,
      ringExpiresAt: now.add(const Duration(seconds: 60)),
    );
    _maximised = true;
    notifyListeners();

    try {
      final conn = await _initiateWithStaleRingRetry(
        chatId: chatId,
        kind: kind,
        idempotencyKey: idempotencyKey,
      );

      // idempotentReplay: the backend served this from cache. The session
      // we just staged above is still the correct local representation —
      // there's no separate "ringing UI already up" to dedupe because we
      // gated entry on `!_initiateInFlight && _session == null`. The flag
      // matters for the case where the app was killed mid-attempt and we
      // recover by replay; in that case `_session == null` on entry and
      // this code path still produces the right state.
      _session = _session!.copyWith(
        callId: conn.callId,
        roomName: conn.roomName,
        livekitUrl: conn.livekitUrl,
        livekitToken: conn.token,
        phase: LocalCallPhase.outgoing,
      );
      _scheduleRingExpiry();
      notifyListeners();

      // Bring up the callkit foreground service so the OS keeps the mic
      // alive when the user backgrounds the app / locks the screen during
      // the call. Without this, Android 13+ throttles mic capture within
      // ~10s of the activity losing foreground and the peer hears silence.
      unawaited(_ensureCallkitForegroundService(_session!));
    } catch (e) {
      _clearSession();
      rethrow;
    } finally {
      _initiateInFlight = false;
    }
  }

  /// Wraps the bare [CallService.initiate] with the one-shot stale-ring
  /// retry from contract §2.4. The HTTP-level retry (network / 5xx) lives
  /// inside [CallService.initiate] itself; this helper adds the one
  /// application-level retry for `caller_busy` against a stale own-ring,
  /// which is a UX decision and belongs at the controller layer.
  Future<CallConnection> _initiateWithStaleRingRetry({
    required String chatId,
    required CallKind kind,
    required String idempotencyKey,
  }) async {
    try {
      return await CallService.initiate(
        chatId: chatId,
        kind: kind,
        idempotencyKey: idempotencyKey,
      );
    } on CallBusyException catch (e) {
      // Belt-and-suspenders against the race documented in contract §3.3:
      // the backend tries to auto-cancel stale own-rings before throwing
      // 409, but a request that lands while the cancel is still in flight
      // can still see caller_busy with a fresh-looking ring. One retry
      // after 1s with the SAME idempotency key catches that race.
      final existing = e.existing;
      if (e.code == 'caller_busy' &&
          existing != null &&
          existing.status == CallStatus.ringing &&
          existing.ageSeconds < 5) {
        await Future<void>.delayed(const Duration(seconds: 1));
        return await CallService.initiate(
          chatId: chatId,
          kind: kind,
          idempotencyKey: idempotencyKey,
        );
      }
      rethrow;
    }
  }

  /// Callee-side: an incoming call arrived (via FCM or socket). Stage it
  /// for the user to accept / reject. Idempotent if already showing.
  void receiveIncoming({
    required String callId,
    required String chatId,
    required String callerUserId,
    required String callerName,
    String? callerPhotoUrl,
    required CallKind kind,
    required DateTime startedAt,
    required DateTime expiresAt,
  }) {
    // De-dup: if we already have this exact incoming call up, no-op.
    final existing = _session;
    if (existing != null && existing.callId == callId) return;

    if (existing != null) {
      // We're already in another call. Auto-reject the new one server-side
      // so the caller hears a busy state, then drop the event locally.
      unawaited(CallService.reject(callId).catchError((_) {}));
      return;
    }

    _session = CallSession(
      callId: callId,
      chatId: chatId,
      peerUserId: callerUserId,
      peerName: callerName,
      peerPhotoUrl: callerPhotoUrl,
      kind: kind,
      phase: LocalCallPhase.incoming,
      initiatedByMe: false,
      startedAt: startedAt,
      ringExpiresAt: expiresAt,
    );
    _maximised = true;
    _scheduleRingExpiry();
    notifyListeners();
  }

  /// Callee accepts. Hits POST /accept, then connects to LiveKit.
  ///
  /// **Idempotent.** If the same call is already past [LocalCallPhase.incoming]
  /// — e.g. the cold-start handoff already drove accept and the bridge's
  /// `actionCallAccept` event arrived afterward — this method returns silently
  /// instead of throwing. This is the only safe behavior because tearing down
  /// an in-flight accept would orphan the LiveKit room.
  ///
  /// Phase progression: `incoming → accepting → connecting → active`. The
  /// transition to `connecting` (not directly to `active`) is what lets the
  /// UI show "Connecting…" instead of a misleading muted-mic icon while
  /// LiveKit's WebRTC handshake completes.
  Future<void> accept() async {
    final s = _session;
    if (s == null || s.callId == null) {
      throw StateError('No incoming call to accept');
    }
    // Idempotency: an accept for this call is already in flight or done.
    switch (s.phase) {
      case LocalCallPhase.accepting:
      case LocalCallPhase.connecting:
      case LocalCallPhase.active:
      case LocalCallPhase.reconnecting:
        return;
      case LocalCallPhase.incoming:
        break;
      case LocalCallPhase.dialing:
      case LocalCallPhase.outgoing:
      case LocalCallPhase.ended:
        throw StateError('Cannot accept call in phase ${s.phase}');
    }

    _session = s.copyWith(phase: LocalCallPhase.accepting);
    notifyListeners();

    try {
      await CallPermissions.ensureForCall(s.kind);
      final conn = await CallService.accept(s.callId!);
      final afterRest = _session;
      if (afterRest == null || afterRest.callId != s.callId) {
        // Session was cleared mid-flight (peer cancelled, ring timeout, etc.).
        return;
      }
      _session = afterRest.copyWith(
        roomName: conn.roomName,
        livekitUrl: conn.livekitUrl,
        livekitToken: conn.token,
        phase: LocalCallPhase.connecting,
        answeredAt: DateTime.now().toUtc(),
      );
      notifyListeners();

      // Ensure the foreground service is up so the mic survives the user
      // backgrounding the app mid-call. For the cold-start accept path
      // (callkit's own ACTION_CALL_ACCEPT broadcast) the service is
      // already running; this call is then an idempotent refresh. For
      // the warm in-app accept path (no native callkit UI was shown),
      // this is the call that actually starts the service.
      unawaited(_ensureCallkitForegroundService(_session!));

      await _connectToLiveKit();
    } catch (e) {
      // Restore phase so the UI returns to the ringing screen and the user
      // can retry or decline. Only restore if we still own this session.
      final current = _session;
      if (current != null &&
          current.callId == s.callId &&
          current.phase == LocalCallPhase.accepting) {
        _session = current.copyWith(phase: LocalCallPhase.incoming);
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Callee rejects an incoming call. Server is silently idempotent.
  Future<void> reject() async {
    final s = _session;
    if (s == null || s.phase != LocalCallPhase.incoming || s.callId == null) {
      _clearSession();
      return;
    }
    final id = s.callId!;
    _clearSession();
    await CallService.reject(id);
  }

  /// Caller cancels an outgoing call before answer.
  Future<void> cancel() async {
    final s = _session;
    if (s == null || s.callId == null) {
      _clearSession();
      return;
    }
    final id = s.callId!;
    _clearSession();
    await CallService.cancel(id);
  }

  /// Either side hangs up an active call.
  Future<void> hangup({
    CallEndReason reason = CallEndReason.normal,
  }) async {
    final s = _session;
    if (s == null) return;
    final id = s.callId;
    await _room.hangup();
    _clearSession();
    if (id != null) {
      await CallService.end(callId: id, reason: reason)
          .catchError((_) => null);
    }
  }

  // ─────────────────────────── In-call controls ────────────────────────

  Future<void> setMicEnabled(bool enabled) => _room.setMicEnabled(enabled);
  Future<void> setCameraEnabled(bool enabled) =>
      _room.setCameraEnabled(enabled);
  Future<void> setSpeakerEnabled(bool enabled) =>
      _room.setSpeakerEnabled(enabled);
  Future<void> switchCamera() => _room.switchCamera();

  Future<void> toggleMic() => setMicEnabled(!_room.currentLocal.micEnabled);
  Future<void> toggleCamera() =>
      setCameraEnabled(!_room.currentLocal.cameraEnabled);
  Future<void> toggleSpeaker() =>
      setSpeakerEnabled(!_room.currentLocal.speakerEnabled);

  // ─────────────────────────── Internals ───────────────────────────────

  /// Look up the caller's display name/photo from the local chat DB and
  /// stage the incoming call. Falls back to a generic label if the chat
  /// isn't in the DB yet (rare — fresh match + immediate call).
  Future<void> _handleSocketIncoming(CallIncomingEvent e) async {
    String name = 'Incoming call';
    String? photoUrl;
    try {
      final repo = await ChatRepositoryHolder.instance();
      final chat = await repo.getChat(e.chatId);
      if (chat != null) {
        final resolved = chat.otherUser.name.trim();
        if (resolved.isNotEmpty) name = resolved;
        photoUrl = chat.otherUser.photoUrl;
      }
    } catch (err) {
      debugPrint('[call] chat lookup for incoming failed: $err');
    }
    receiveIncoming(
      callId: e.callId,
      chatId: e.chatId,
      callerUserId: e.callerId,
      callerName: name,
      callerPhotoUrl: photoUrl,
      kind: e.kind,
      startedAt: e.startedAt,
      expiresAt: e.expiresAt,
    );
  }

  /// Handle a `call.snapshot` from the server — the authoritative view of
  /// which calls the user is currently involved in. Fires on every WS
  /// connect (cold boot, foreground resume, network flap). Drives the
  /// post-force-kill recovery path described in CALLS_FRONTEND_CONTRACT.md
  /// §2: rebuild the controller's session and (for active calls) rejoin
  /// the LiveKit room using the freshly-minted token the server included.
  void _onSnapshot(CallSnapshotEvent event) {
    if (event.calls.isEmpty) {
      // Authoritative "no calls". Clear local state ONLY when we're not
      // mid-handshake with LiveKit — if we have a live `_room` connection,
      // the user is in a real call right now and an empty snapshot is more
      // likely a stale/racing emission than a real "the call ended" signal.
      // The genuine end will arrive via `call.ended` on the events stream.
      if (_session != null &&
          _room.currentRoom == null &&
          !_initiateInFlight) {
        _clearSession();
      }
      return;
    }

    // Backend currently enforces at most one live call per user, but the
    // payload is a list so iterate defensively.
    for (final entry in event.calls) {
      final existing = _session;

      // Dedupe by callId — if we already track this call, leave it alone.
      // The existing session may be in a finer-grained phase than what the
      // snapshot can express (e.g. `accepting` / `connecting`), and we
      // don't want to roll it back.
      if (existing != null && existing.callId == entry.callId) {
        continue;
      }

      // Different callId (or no local session) — server is authoritative.
      // Drop whatever we had and adopt the server's view.
      unawaited(_adoptSnapshotEntry(entry));
    }
  }

  /// Rebuild controller state from one snapshot entry. For `active` calls
  /// this also rejoins the LiveKit room with the snapshot's freshly minted
  /// token. For `ringing` entries it just stages the session + ring expiry
  /// timer — the eventual `call.accepted` / `call.cancelled` / `call.ended`
  /// event will drive the next transition.
  Future<void> _adoptSnapshotEntry(CallSnapshotEntry entry) async {
    // If we had a different call locally, tear it down cleanly so the
    // LiveKit room (if any) is released before we try to join the new one.
    if (_session != null && _session!.callId != entry.callId) {
      await _room.hangup();
      _session = null;
    }

    final peerName = (entry.peerName == null || entry.peerName!.trim().isEmpty)
        ? 'Unknown'
        : entry.peerName!;

    // Pick the local phase that best matches the snapshot. For `active`
    // we deliberately go straight to `active` (skipping `connecting`)
    // because the call IS active server-side — the LiveKit handshake we
    // run below is a *rejoin*, not the initial connect, and the UI should
    // already show the in-call layout.
    final LocalCallPhase phase;
    if (entry.status == CallStatus.active) {
      phase = LocalCallPhase.active;
    } else if (entry.role == 'caller') {
      phase = LocalCallPhase.outgoing;
    } else {
      phase = LocalCallPhase.incoming;
    }

    _session = CallSession(
      callId: entry.callId,
      chatId: entry.chatId,
      peerUserId: entry.peerId,
      peerName: peerName,
      peerPhotoUrl: entry.peerPhotoUrl,
      kind: entry.kind,
      phase: phase,
      initiatedByMe: entry.role == 'caller',
      startedAt: entry.startedAt,
      // For ringing, prefer the server's expiresAt; for active it's null
      // and we synthesize a 60s window that won't actually fire because
      // the ring-expiry timer no-ops once the call is active.
      ringExpiresAt: entry.expiresAt ??
          entry.startedAt.add(const Duration(seconds: 60)),
      roomName: entry.roomName,
      livekitUrl: entry.livekitUrl,
      livekitToken: entry.livekitToken,
      answeredAt: entry.answeredAt,
    );
    _maximised = true;
    _scheduleRingExpiry();
    notifyListeners();

    if (entry.status == CallStatus.active) {
      // Rejoin the LiveKit room. The token in the snapshot is freshly
      // minted (TTL ~4h) so we use it directly — never fall back to any
      // token cached locally before the kill.
      try {
        await _room.connect(
          url: entry.livekitUrl,
          token: entry.livekitToken,
          publishVideo: entry.kind == CallKind.video,
        );
        // The process that died on cold-kill took the callkit foreground
        // service with it. Bring it back so the resumed call survives a
        // subsequent screen-lock / background.
        unawaited(_ensureCallkitForegroundService(_session!));
      } catch (err) {
        debugPrint('[call] snapshot resume failed to rejoin LiveKit: $err');
        _errorEvents.add(
          "Couldn't resume the call. It will end shortly.",
        );
        // Hand off to the normal end-call path so the server cleans up.
        await hangup(reason: CallEndReason.network);
      }
    } else if (entry.status == CallStatus.ringing &&
        entry.role == 'caller') {
      // Resuming an outgoing ring after a cold-kill — restart the service
      // so audio survives if the user immediately re-backgrounds the app.
      // For ringing+callee we deliberately don't start the service because
      // there's no audio in flight yet; the in-app incoming UI is showing.
      unawaited(_ensureCallkitForegroundService(_session!));
    }
  }

  /// Connects to the LiveKit room and flips phase to [LocalCallPhase.active]
  /// on success. Pre-condition: caller has set phase to
  /// [LocalCallPhase.connecting] (or the equivalent transitional state) so
  /// the UI shows "Connecting…" during the handshake.
  Future<void> _connectToLiveKit() async {
    final s = _session;
    if (s == null || s.livekitUrl == null || s.livekitToken == null) return;
    try {
      await _room.connect(
        url: s.livekitUrl!,
        token: s.livekitToken!,
        publishVideo: s.kind == CallKind.video,
      );
      // Promote to active only after LiveKit handshake + track publish.
      // Until this point local mic/camera flags are still false, so the
      // UI was correctly hiding the controls behind a "Connecting…" state.
      final current = _session;
      if (current != null && current.callId == s.callId) {
        _session = current.copyWith(phase: LocalCallPhase.active);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[call] LiveKit connect failed: $e');
      _errorEvents.add(
        "Couldn't connect to the call. Check your internet and try again.",
      );
      // Couldn't connect — bail out cleanly.
      await hangup(reason: CallEndReason.network);
    }
  }

  void _onSocketEvent(CallEvent event) {
    final s = _session;
    switch (event) {
      case CallIncomingEvent e:
        // Socket payload is intentionally lean — name/photo are looked up
        // from the local chat DB (see CALLS_CONTRACT_ACTUAL.md §4). The
        // lookup is async so we wrap in unawaited; receiveIncoming itself
        // de-dups by callId in case FCM beat the socket.
        unawaited(_handleSocketIncoming(e));

      case CallAcceptedEvent e:
        if (s == null || s.callId != e.callId) return;
        // F1 multi-device dismissal: if this device's session is still in
        // incoming state, our other device accepted — dismiss our UI. If
        // we ARE the caller, transition to connecting and start the LiveKit
        // handshake. Phase will flip to active inside _connectToLiveKit
        // once room.connect + track publish completes.
        if (s.initiatedByMe && s.phase == LocalCallPhase.outgoing) {
          _session = s.copyWith(
            phase: LocalCallPhase.connecting,
            answeredAt: e.answeredAt,
          );
          notifyListeners();
          unawaited(_connectToLiveKit());
        } else if (!s.initiatedByMe && s.phase == LocalCallPhase.incoming) {
          // Sibling device accepted — clear local UI silently.
          _clearSession();
        }

      case CallRejectedEvent e:
        if (s == null || s.callId != e.callId) return;
        // F1: covers both "peer rejected our outgoing call" and "our other
        // device rejected an incoming call" — same UI outcome.
        _clearSession();

      case CallCancelledEvent e:
        if (s == null || s.callId != e.callId) return;
        // Server only sends cancelled to the callee — caller dismissed.
        _clearSession();

      case CallEndedEvent e:
        if (s == null || s.callId != e.callId) return;
        unawaited(_room.hangup());
        _clearSession();
    }
  }

  void _onRoomEvent(RoomManagerEvent event) {
    switch (event) {
      case RoomReconnectingEvent _:
        final s = _session;
        if (s != null && s.phase == LocalCallPhase.active) {
          _session = s.copyWith(phase: LocalCallPhase.reconnecting);
          notifyListeners();
        }
      case RoomReconnectedEvent _:
        final s = _session;
        if (s != null && s.phase == LocalCallPhase.reconnecting) {
          _session = s.copyWith(phase: LocalCallPhase.active);
          notifyListeners();
        }
      case RoomDisconnectedEvent e:
        if (!e.intentional) {
          // Lost connection for good — end the call from our side.
          unawaited(hangup(reason: CallEndReason.network));
        }
      case ParticipantTracksChangedEvent _:
        // UI listens to room.events directly for this; no controller state
        // change.
        notifyListeners();
      default:
        break;
    }
  }

  void _scheduleRingExpiry() {
    _ringExpiryTimer?.cancel();
    final s = _session;
    if (s == null) return;
    final delay = s.ringExpiresAt.difference(DateTime.now().toUtc());
    if (delay.isNegative) return;
    _ringExpiryTimer = Timer(delay, () {
      // Server should have already sent call.ended with reason='missed' by
      // now. This is a belt-and-suspenders safety net.
      final cur = _session;
      if (cur == null) return;
      if (cur.phase == LocalCallPhase.outgoing ||
          cur.phase == LocalCallPhase.incoming) {
        _clearSession();
      }
    });
  }

  /// Single source of truth for ending the local call state.
  ///
  /// Structurally guarantees that:
  /// 1. The controller's session is nulled (UI dismisses).
  /// 2. The LiveKit room is disconnected — releases mic/camera/audio so the
  ///    OS-level recording indicator goes away even on paths that historically
  ///    only nulled the session (reject, cancel, sibling-accepted, ring
  ///    expiry, certain socket events).
  /// 3. The callkit plugin's native record of this call is evicted so it
  ///    doesn't accumulate in `activeCalls()` and pollute future cold-start
  ///    handoffs.
  ///
  /// `LiveKitRoomManager.hangup()` is idempotent (no-op when no room) so
  /// callers that already disconnected (e.g. `hangup()`) cost nothing.
  ///
  /// Ordering matters:
  /// - Session is nulled first so the callkit echo (`actionCallEnded` ->
  ///   bridge -> `controller.hangup()`) sees `_session == null` and returns
  ///   early instead of running a second termination.
  void _clearSession() {
    final priorCallId = _session?.callId;
    _session = null;
    _maximised = true;
    _ringExpiryTimer?.cancel();
    _ringExpiryTimer = null;
    notifyListeners();
    // Tear down the LiveKit room unconditionally. This is the load-bearing
    // line that closes the mic leak: prior to this, six different
    // termination paths cleared the session without touching the room.
    unawaited(_room.hangup());
    // Stop our own foreground service so the persistent notification goes
    // away and the OS releases the mic/CPU keepalive. Idempotent — safe to
    // call even if the service was never started for this session.
    unawaited(CallAudioFgChannel.stop());
    if (priorCallId != null) {
      unawaited(_evictFromCallkit(priorCallId));
    }
  }

  Future<void> _evictFromCallkit(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('[call] callkit endCall failed for $callId: $e');
    }
  }

  /// Bring up the callkit ongoing-call notification and its accompanying
  /// foreground service. On Android the package's `CallkitNotificationService`
  /// runs with `foregroundServiceType="phoneCall"`, which is what tells the
  /// OS to keep the microphone alive while the activity is in background or
  /// the screen is locked. Without this, Android 13+ suspends mic capture
  /// within ~10 seconds of the activity losing foreground and the peer
  /// hears silence until the user opens the app again.
  ///
  /// Idempotent on the Android service side — calling `start` multiple times
  /// just re-posts the existing notification with the same content.
  Future<void> _ensureCallkitForegroundService(CallSession s) async {
    final callId = s.callId;
    // [CALL-FG] tag stays in place so future regressions are easy to grep.
    // Cheap diagnostic; `CallAudioFgChannel.start` plus the native
    // `CallAudioFGS` tag give the full picture from Dart down to startForeground.
    if (callId == null) {
      // ignore: avoid_print
      print('[CALL-FG] skip: session has null callId');
      return;
    }
    // ignore: avoid_print
    print(
      '[CALL-FG] start callId=$callId peer=${s.peerName} '
      'kind=${s.kind == CallKind.video ? 'video' : 'voice'}',
    );

    // We do NOT call `FlutterCallkitIncoming.startCall(...)` here even
    // though the package supports it. Reasons:
    //   1. The package's `CallkitNotificationService` was silently failing
    //      to elevate to foreground in our testing (getOnGoingCallNotification
    //      returning null with no exception). Our own service is now the
    //      load-bearing one for mic survival.
    //   2. With our own service running, calling `startCall` produces a
    //      DUPLICATE persistent notification (one from the package, one
    //      from us) which is bad UX.
    // FCM cold-start incoming calls still go through `showCallkitIncoming`
    // (in call_fcm_handler.dart), which is a separate code path with its
    // own UX requirements (full-screen incoming UI, ringtone, native answer
    // buttons over the lock screen).
    try {
      await CallAudioFgChannel.start(
        peerName: s.peerName.isEmpty ? 'Call' : s.peerName,
        kind: s.kind == CallKind.video ? 'video' : 'voice',
      );
      // ignore: avoid_print
      print('[CALL-FG] OK start returned for $callId');
    } catch (e, st) {
      // Non-fatal — the call continues, just without the mic-survival
      // guarantee when backgrounded. Logged so the symptom is traceable
      // if we ever see "peer hears silence after lock" reports again.
      // ignore: avoid_print
      print('[CALL-FG] FAIL start for $callId: $e\n$st');
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _snapshotSub?.cancel();
    _roomSub?.cancel();
    _localSub?.cancel();
    _ringExpiryTimer?.cancel();
    unawaited(_errorEvents.close());
    unawaited(_room.dispose());
    super.dispose();
  }
}

/// Singleton holder so any widget can grab the controller without a
/// provider. Pattern matches ChatSocketServiceHolder etc.
class ActiveCallControllerHolder {
  static ActiveCallController? _instance;

  static Future<ActiveCallController> instance() async {
    final existing = _instance;
    if (existing != null) return existing;
    final socket = await ChatSocketServiceHolder.instance();
    final created = ActiveCallController(socket: socket);
    _instance = created;
    return created;
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}
