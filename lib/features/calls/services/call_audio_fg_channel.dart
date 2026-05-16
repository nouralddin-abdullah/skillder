import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin wrapper over the `com.skillder.app/call_audio_fg` method channel.
///
/// On Android, the native `CallAudioForegroundService` runs while a call is
/// in flight so the OS doesn't suspend the microphone when the activity
/// backgrounds or the screen locks. We own this service ourselves (rather
/// than relying on `flutter_callkit_incoming.startCall`) because the
/// package's `CallkitNotificationService` was silently failing to elevate
/// to foreground in our testing — `getOnGoingCallNotification` returning
/// null with no exception, the service stayed non-foreground, Android
/// killed it ~5s after backgrounding, and the WebRTC peer connection died
/// with it. Our service logs its lifecycle so any future regression is
/// visible in logcat under tag `CallAudioFGS`.
///
/// iOS is a no-op for now — CallKit / AVAudioSession handles VoIP
/// audio survival differently, and we don't ship calls on iOS yet.
class CallAudioFgChannel {
  static const _channel = MethodChannel('com.skillder.app/call_audio_fg');

  /// Idempotent — safe to call multiple times. The native service ignores
  /// duplicate start commands beyond the first (it just re-posts the
  /// foreground notification with the same content).
  static Future<void> start({
    required String peerName,
    required String kind, // 'voice' | 'video'
  }) async {
    if (!defaultTargetPlatform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('start', {
        'peer': peerName,
        'kind': kind,
      });
    } catch (e) {
      // Non-fatal — the call continues without background mic survival.
      // Logged so the symptom is traceable if we ever see it again.
      // ignore: avoid_print
      print('[CALL-AUDIO-FG] start failed: $e');
    }
  }

  /// Idempotent — safe to call even if the service isn't running.
  static Future<void> stop() async {
    if (!defaultTargetPlatform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (e) {
      // ignore: avoid_print
      print('[CALL-AUDIO-FG] stop failed: $e');
    }
  }
}

extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
