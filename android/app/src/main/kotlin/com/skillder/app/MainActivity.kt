package com.skillder.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Method-channel name matches the Dart side's `CallAudioFgChannel`.
    private val callAudioChannel = "com.skillder.app/call_audio_fg"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            callAudioChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val peer = call.argument<String>("peer") ?: "Call"
                    val kind = call.argument<String>("kind") ?: "voice"
                    CallAudioForegroundService.start(applicationContext, peer, kind)
                    result.success(null)
                }
                "stop" -> {
                    CallAudioForegroundService.stop(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Default Flutter behavior: when its Navigator has nothing left to pop,
    // the back button calls finish() on this activity → engine torn down
    // → process gets reaped → next launch is a cold start. For an active
    // call that means the LiveKit connection dies and the user reopens to
    // the splash screen instead of being still in the call.
    //
    // Override so a root-level back press just minimises the app instead.
    // FlutterActivity only delegates here AFTER Flutter's own Navigator
    // has run out of routes to pop, so in-app back navigation (closing a
    // chat to return to the chat list, dismissing a dialog, etc.) still
    // works as expected — this only intercepts the final "exit the app"
    // press. Matches WhatsApp / Telegram / Discord / Instagram, where
    // exiting is done by swiping the task out of Recents, not by holding
    // back until the process dies.
    //
    // We don't register an OnBackInvokedCallback for Android 13+ predictive
    // back here because the manifest doesn't opt in via
    // android:enableOnBackInvokedCallback="true". Without that opt-in,
    // Android continues to dispatch through onBackPressed on every API
    // level we support, and this override covers all of them.
    override fun onBackPressed() {
        // Deliberately not calling super — super.onBackPressed() finishes
        // the activity, which is exactly what we're trying to avoid.
        moveTaskToBack(true)
    }
}
