package com.skillder.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

// Minimal foreground service whose entire job is to keep the app process
// alive (mic + network) while a call is in flight. We run this in parallel
// to flutter_callkit_incoming's own notification service because that
// package's `CallkitNotificationService` was silently failing to elevate
// (getOnGoingCallNotification returning null → no startForeground call →
// Android kills the implicit-foreground service after ~5s → WebRTC peer
// connection torn down → mic dies). Owning the service ourselves removes
// the silent-fallback paths and gives us logcat visibility on every
// transition so future regressions are obvious.
//
// foregroundServiceType="phoneCall|microphone" (declared in the manifest)
// is what tells the OS this is a legitimate VoIP service. On Android 14+
// each type requires the corresponding FOREGROUND_SERVICE_* permission —
// both are declared in AndroidManifest.xml.
class CallAudioForegroundService : Service() {

    companion object {
        private const val TAG = "CallAudioFGS"
        private const val CHANNEL_ID = "skillder_call_audio"
        private const val CHANNEL_NAME = "Ongoing calls"
        private const val NOTIF_ID = 91101

        // Intent extras for the peer name shown in the notification.
        private const val EXTRA_PEER = "peer_name"
        private const val EXTRA_KIND = "call_kind"

        fun start(context: Context, peerName: String, kind: String) {
            Log.i(TAG, "start() requested peer=$peerName kind=$kind")
            val intent = Intent(context, CallAudioForegroundService::class.java).apply {
                putExtra(EXTRA_PEER, peerName)
                putExtra(EXTRA_KIND, kind)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            Log.i(TAG, "stop() requested")
            val intent = Intent(context, CallAudioForegroundService::class.java)
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "onCreate")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val peer = intent?.getStringExtra(EXTRA_PEER) ?: "Call"
        val kind = intent?.getStringExtra(EXTRA_KIND) ?: "voice"
        Log.i(TAG, "onStartCommand peer=$peer kind=$kind flags=$flags startId=$startId")
        ensureChannel()
        val notification = buildNotification(peer, kind)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ requires the type when startForeground is called
                // from a service declared with one. Using phoneCall covers
                // mic-access-in-background on Android 13+, and combined with
                // the manifest's `phoneCall|microphone` type the OS won't
                // strip mic access mid-call.
                startForeground(
                    NOTIF_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                )
            } else {
                startForeground(NOTIF_ID, notification)
            }
            Log.i(TAG, "startForeground OK")
        } catch (t: Throwable) {
            // Log loudly — if this ever fires we want to see it in logcat.
            // The most likely causes are:
            // - ForegroundServiceStartNotAllowedException on Android 12+
            //   (caller wasn't in foreground / didn't have allowlist).
            // - Missing FOREGROUND_SERVICE_MICROPHONE permission on
            //   Android 14+.
            Log.e(TAG, "startForeground FAILED", t)
        }
        // START_STICKY so the system tries to restart us if it kills us
        // for memory pressure — the call is still alive in that case.
        return START_STICKY
    }

    override fun onDestroy() {
        Log.i(TAG, "onDestroy")
        super.onDestroy()
    }

    // Stop ourselves when the user swipes the app off Recents (or otherwise
    // force-kills the task). Without this override, foreground services
    // survive the activity death by design — the "Call in progress"
    // notification would persist forever even though the app is gone and
    // there's no Dart code running to act on it. The controller's
    // `_clearSession` is the normal stop path (it calls
    // `CallAudioFgChannel.stop()`), but it can't run when the process
    // is killed without warning.
    //
    // We do NOT also call POST /calls/:id/end here — that would require
    // shipping the auth token and call id into the service and running an
    // HTTP request inside a ~5 second teardown window, which is fragile.
    // LiveKit detects the peer disconnect on its own after ~20s and ends
    // the call server-side; the snapshot mechanism then catches the user
    // up when they reopen the app.
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(TAG, "onTaskRemoved — task swiped away, stopping service")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Persistent notification while a Skillder call is in progress"
            setShowBadge(false)
            enableLights(false)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(peerName: String, kind: String): Notification {
        // Tapping the notification re-opens the app's main activity so the
        // user gets back to the call screen.
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val title = if (kind == "video") "Video call in progress" else "Call in progress"
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentTitle(title)
            .setContentText(peerName)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}
