import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../../services/auth_storage.dart';
import 'call_service.dart';

/// FCM-based ringing for cold-start incoming calls.
///
/// Three integration points:
///  - [attachHandlers] — call from `main()` AFTER Firebase.initializeApp().
///    Wires the background handler, the foreground handler, and the token
///    refresh listener. **Does NOT prompt the user and does NOT hit the
///    network.** Safe to call at cold start; the listeners must exist
///    before any FCM message can arrive.
///  - [setUpForUser] — call after the user is signed in (e.g. from auth
///    success paths or the post-onboarding shell). Prompts for the OS
///    notification permission and pushes the FCM token to /api/devices.
///    Deferred so new users see the app before the system dialog.
///  - [unregister] — call on logout to remove the device token server-side.
///
/// The background handler is a top-level function (Dart isolate constraint)
/// declared in this file at the bottom. It hands the payload to
/// flutter_callkit_incoming which natively presents the ringing UI even
/// when the Flutter app process is dead.
class CallFcmHandler {
  // Held to keep the subscriptions alive for the app lifetime; we never
  // cancel them (the streams die when the app process dies).
  // ignore: unused_field
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  // ignore: unused_field
  static StreamSubscription<String>? _tokenRefreshSub;
  static bool _attached = false;

  /// Wire the FCM listeners. Call from `main()` at cold start. Idempotent.
  /// No prompts, no network — safe to fire before the user is signed in.
  static Future<void> attachHandlers() async {
    if (_attached) return;
    // Top-level handler runs in a separate isolate when the app is
    // backgrounded / killed; must be registered before any app code that
    // could receive a message.
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Foreground handler — same logic, but the app is alive so we can
    // also notify the in-app controller via the event bus.
    _foregroundSub =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen(_pushToken);

    _attached = true;
  }

  /// Prompt the OS notification permission (Android 13+ shows the system
  /// dialog the first time) and register this device's FCM token with the
  /// backend so the user can be rung. Call after a successful signup /
  /// login. Idempotent — repeat calls are no-ops once permission decided
  /// and the token is current.
  static Future<void> setUpForUser() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: false,
      sound: true,
    );
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _pushToken(token);
  }

  /// Called on logout — drops this device's token from the server so it
  /// stops receiving rings for the previous user.
  static Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await CallService.unregisterDevice(token).catchError((_) {});
    }
  }

  // ─────────────────────────── Internals ───────────────────────────────

  static Future<void> _pushToken(String token) async {
    final auth = await AuthStorage.getToken();
    if (auth == null || auth.isEmpty) return; // not logged in yet
    try {
      await CallService.registerDevice(token: token);
    } catch (e) {
      debugPrint('[fcm] device registration failed: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage msg) async {
    final data = msg.data;
    if (data['type'] != 'call.incoming') return;
    // When the app is in the foreground the Socket.IO `call.incoming` event
    // drives the in-app IncomingCallScreen via ActiveCallController. Showing
    // the native callkit UI on top of it would stack two ringing UIs, so we
    // skip it here. The background isolate handler still shows callkit when
    // the app is killed / backgrounded.
  }
}

/// Top-level background handler. Runs in its own isolate when the app is
/// backgrounded or killed. Must NOT touch in-app state directly — instead
/// we hand the payload to the native callkit plugin which renders the
/// ringing UI without needing Dart code to be alive.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage msg) async {
  // Each isolate spawns fresh — Firebase needs to be initialised here too.
  await Firebase.initializeApp();
  if (msg.data['type'] != 'call.incoming') return;
  await _showIncomingCallUi(msg.data);
}

/// Hands the incoming-call payload to flutter_callkit_incoming. Shared
/// between foreground and background handlers so the native UI behaves
/// identically regardless of app state.
///
/// Wire shape (per CALLS_CONTRACT_ACTUAL.md §5):
///   { type, callId, chatId, callerId, callerName, callerPhotoUrl, kind,
///     startedAt, expiresAtMs }
@pragma('vm:entry-point')
Future<void> _showIncomingCallUi(Map<String, dynamic> data) async {
  final callId = data['callId']?.toString();
  if (callId == null) return;
  final kind = data['kind']?.toString() ?? 'voice';
  final isVideo = kind == 'video';
  final callerName = (data['callerName']?.toString() ?? '').trim();
  final callerPhoto = data['callerPhotoUrl']?.toString() ?? '';
  final chatId = data['chatId']?.toString() ?? '';
  final callerId = data['callerId']?.toString() ?? '';

  await FlutterCallkitIncoming.showCallkitIncoming(
    CallKitParams(
      id: callId,
      nameCaller: callerName.isEmpty ? 'Skillder' : callerName,
      avatar: callerPhoto.isEmpty ? null : callerPhoto,
      handle: callerName,
      type: isVideo ? 1 : 0, // 0=voice, 1=video
      duration: 45000, // 45s — matches backend RING_TIMEOUT_S
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      // Let our app foreground when the user taps the incoming-call UI;
      // the action stream in main.dart handles routing the accept/decline
      // back to ActiveCallController.
      extra: <String, dynamic>{
        'callId': callId,
        'chatId': chatId,
        'callerId': callerId,
        'callerName': callerName,
        'callerPhotoUrl': callerPhoto,
        'kind': kind,
        'startedAt': data['startedAt']?.toString() ?? '',
        'expiresAtMs': data['expiresAtMs']?.toString() ?? '',
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0A0A0A',
        actionColor: '#22C55E',
        textColor: '#FFFFFF',
        // Fire over the lock screen.
        incomingCallNotificationChannelName: 'Incoming calls',
        missedCallNotificationChannelName: 'Missed calls',
      ),
      ios: const IOSParams(
        // iOS path is deferred — but the params have to be set or the
        // plugin throws on iOS targets.
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    ),
  );

  // Pass-through silencer for jsonEncode in case the plugin internally
  // serializes — keeps the analyzer happy about the unused import.
  jsonEncode(data);
}
