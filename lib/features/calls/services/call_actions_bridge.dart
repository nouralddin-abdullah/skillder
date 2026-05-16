import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart' as ck;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../controllers/active_call_controller.dart';
import '../models/call_models.dart';

/// Bridges native callkit actions (Accept/Decline taps on the lock-screen
/// ringing UI) into [ActiveCallController].
///
/// Why this exists: the FCM background isolate shows the callkit UI but
/// can't touch the in-app controller (different isolates). When the user
/// taps Accept, Android launches the main app and we need to reconstruct
/// the [CallSession] from the callkit event payload so the controller can
/// take over. This class subscribes to FlutterCallkitIncoming.onEvent and
/// performs that reconstruction.
class CallActionsBridge {
  static StreamSubscription<ck.CallEvent?>? _sub;
  static ActiveCallController? _controller;

  /// Wire the bridge once. Safe to call multiple times — second call is a
  /// no-op. Pass the app-root [ActiveCallController].
  static void attach(ActiveCallController controller) {
    if (_sub != null && _controller == controller) return;
    _sub?.cancel();
    _controller = controller;
    _sub = FlutterCallkitIncoming.onEvent.listen(_handle);
  }

  static Future<void> detach() async {
    await _sub?.cancel();
    _sub = null;
    _controller = null;
  }

  /// Maximum age of an `activeCalls()` entry we consider live. The FCM TTL
  /// is 60s and the server-side ring timeout is 45s, so anything older than
  /// 60s is definitionally a ghost from a past test/session.
  static const Duration _maxFreshAge = Duration(seconds: 60);

  /// Cold-start handoff.
  ///
  /// When the app was killed and the user tapped Accept on the native
  /// callkit notification, the Android side fires `actionCallAccept` BEFORE
  /// Flutter's event listener is alive — that event is lost. The plugin
  /// persists the call (with `isAccepted: true`) in its native store, which
  /// we query here to recover the action.
  ///
  /// **Staleness**: the plugin keeps accepted entries in `activeCalls()`
  /// indefinitely (until `endCall(id)` is called). After even a single
  /// previous test session, we'll see ghost entries with `isAccepted: true`
  /// whose server-side calls are long dead. Processing them produces
  /// "Call is no longer ringing" errors AND leaves the controller stuck
  /// with a phantom session that auto-rejects subsequent legitimate calls.
  ///
  /// Defense: filter every entry by `extra.startedAt` freshness. Evict the
  /// stale ones from the plugin store via `endCall(id)`. Process only the
  /// newest fresh entry, if any.
  static Future<void> processColdStartLaunch(
    ActiveCallController controller,
  ) async {
    final List<dynamic> rawCalls;
    try {
      final raw = await FlutterCallkitIncoming.activeCalls();
      if (raw is! List) return;
      rawCalls = raw;
    } catch (e) {
      debugPrint('[callkit] activeCalls failed: $e');
      return;
    }
    if (rawCalls.isEmpty) return;

    final now = DateTime.now().toUtc();
    final fresh = <_CallkitEntry>[];
    final stale = <String>[];

    for (final raw in rawCalls) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      final id = entry['id']?.toString();
      final extraRaw = entry['extra'];
      final payload =
          extraRaw is Map ? Map<String, dynamic>.from(extraRaw) : null;
      if (id == null || payload == null) {
        if (id != null) stale.add(id);
        continue;
      }
      final startedAt = DateTime.tryParse(
        payload['startedAt']?.toString() ?? '',
      );
      if (startedAt == null || now.difference(startedAt) > _maxFreshAge) {
        stale.add(id);
        continue;
      }
      fresh.add(_CallkitEntry(
        id: id,
        startedAt: startedAt,
        payload: payload,
        isAccepted: entry['isAccepted'] == true,
      ));
    }

    // Evict stale entries so they don't pollute the next cold-start.
    for (final id in stale) {
      try {
        await FlutterCallkitIncoming.endCall(id);
      } catch (_) {}
    }

    if (fresh.isEmpty) return;

    // Process the newest fresh entry — if multiple, the most recent wins.
    fresh.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final winner = fresh.first;

    // Evict any other fresh entries — we can only handle one call at a time
    // and the user expressed intent on the newest notification.
    for (final other in fresh.skip(1)) {
      try {
        await FlutterCallkitIncoming.endCall(other.id);
      } catch (_) {}
    }

    _seedFromPayload(controller, winner.payload);

    if (!winner.isAccepted) {
      // Native UI is still ringing or the user opened the app via the
      // notification body — let the in-app incoming screen take over.
      return;
    }

    // User already tapped Accept on the cold-start native UI. The plugin
    // marked the call accepted on its side but our backend never got the
    // POST /accept request. Drive it now.
    //
    // `controller.accept()` is idempotent — if the bridge's onEvent stream
    // delivers a buffered `actionCallAccept` after we kick this off, the
    // second accept becomes a no-op.
    try {
      await controller.accept();
    } catch (e) {
      debugPrint('[callkit] cold-start accept failed: $e');
      // Permanent failure (e.g., backend says "no longer ringing"). Evict
      // the plugin entry and clear our seeded session so a fresh incoming
      // call arriving via the bridge isn't auto-rejected by receiveIncoming's
      // "already in another call" dedup branch. `reject()` runs
      // _clearSession (which itself evicts from callkit as a backstop) and
      // fires a benign POST /reject that the backend silently accepts.
      try {
        await controller.reject();
      } catch (_) {}
    }
  }

  static Future<void> _handle(ck.CallEvent? event) async {
    final controller = _controller;
    if (event == null || controller == null) return;

    final body = event.body;
    final extra = body is Map ? Map<String, dynamic>.from(body) : null;
    final extraData = extra?['extra'];
    final payload =
        extraData is Map ? Map<String, dynamic>.from(extraData) : null;

    switch (event.event) {
      case ck.Event.actionCallIncoming:
        // Native UI is showing — seed the controller with the same data
        // so the in-app state reflects "we're ringing" once the user
        // returns to the app.
        if (payload != null) _seedFromPayload(controller, payload);

      case ck.Event.actionCallAccept:
        // User tapped Accept on lock screen. Seed first so accept() has
        // the callId, then accept. `controller.accept()` is idempotent —
        // if the cold-start handoff already drove accept for this callId,
        // this call returns silently.
        if (payload != null) _seedFromPayload(controller, payload);
        try {
          await controller.accept();
        } catch (e) {
          // Do NOT auto-reject. The earlier version of this catch called
          // reject() which would `_clearSession()` and orphan an in-flight
          // accept whose REST/LiveKit handshake was still completing.
          // The in-app UI (incoming screen) surfaces permission denials
          // and other recoverable errors; this listener is a fallback.
          debugPrint('[callkit] accept failed: $e');
        }

      case ck.Event.actionCallDecline:
        if (payload != null) _seedFromPayload(controller, payload);
        try {
          await controller.reject();
        } catch (e) {
          debugPrint('[callkit] decline failed: $e');
        }

      case ck.Event.actionCallEnded:
      case ck.Event.actionCallTimeout:
        // Native UI auto-dismissed (timeout or remote ended). Mirror to
        // the controller in case we missed the socket event.
        await controller.hangup(reason: CallEndReason.normal);

      case ck.Event.actionCallToggleMute:
        if (body is Map && body['isMuted'] is bool) {
          await controller.setMicEnabled(!(body['isMuted'] as bool));
        }

      default:
        break;
    }
  }

  static void _seedFromPayload(
    ActiveCallController controller,
    Map<String, dynamic> p,
  ) {
    final callId = p['callId']?.toString();
    final chatId = p['chatId']?.toString();
    final callerId = p['callerId']?.toString();
    if (callId == null || chatId == null || callerId == null) return;

    // De-dup is handled by receiveIncoming().
    final kind = p['kind']?.toString() == 'video'
        ? CallKind.video
        : CallKind.voice;
    final startedAt = DateTime.tryParse(p['startedAt']?.toString() ?? '') ??
        DateTime.now().toUtc();
    final expiresMs = int.tryParse(p['expiresAtMs']?.toString() ?? '');
    final expiresAt = expiresMs != null
        ? DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true)
        : startedAt.add(const Duration(seconds: 45));
    final photoUrl = p['callerPhotoUrl']?.toString();

    controller.receiveIncoming(
      callId: callId,
      chatId: chatId,
      callerUserId: callerId,
      callerName: (p['callerName']?.toString() ?? '').trim().isEmpty
          ? 'Skillder'
          : p['callerName']!.toString(),
      callerPhotoUrl: (photoUrl == null || photoUrl.isEmpty) ? null : photoUrl,
      kind: kind,
      startedAt: startedAt,
      expiresAt: expiresAt,
    );
  }
}

/// Parsed shape of a single entry returned by `FlutterCallkitIncoming.activeCalls()`.
class _CallkitEntry {
  final String id;
  final DateTime startedAt;
  final Map<String, dynamic> payload;
  final bool isAccepted;
  const _CallkitEntry({
    required this.id,
    required this.startedAt,
    required this.payload,
    required this.isAccepted,
  });
}
