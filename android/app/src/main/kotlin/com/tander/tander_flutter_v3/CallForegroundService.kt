package com.tander.tander_flutter_v3

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person

/**
 * Foreground service that keeps the app process alive while a Twilio call
 * is active, and surfaces the OUT-OF-APP call presence: a CallStyle
 * notification with a live timer + a working Hang Up button, so the call
 * follows the user when they leave Tander.
 *
 * Started from TwilioCallManager's connect() (ACTION_START), upgraded to a
 * running timer once the peer joins (ACTION_CONNECTED), torn down on
 * disconnect (ACTION_STOP). The Hang Up button posts ACTION_HANGUP back
 * here, which drives a full hangup (backend end + Twilio disconnect + UI
 * clear) via TwilioCallManager.hangUpFromNotification().
 *
 * Android 14+ requires the foregroundServiceType to be set BOTH in the
 * manifest <service> declaration AND in startForeground (third arg).
 *
 * Uses CHANNEL_CALL_ONGOING (IMPORTANCE_DEFAULT) — the LOW channel can't
 * render the CallStyle template / system call chip on API 31+.
 */
class CallForegroundService : Service() {

    companion object {
        private const val TAG = "CallForegroundService"
        const val NOTIFICATION_ID = 0xCA11
        const val EXTRA_CALLER_NAME = "callerName"
        const val EXTRA_CALL_TYPE = "callType"
        const val ACTION_START = "com.tander.app.CALL_FOREGROUND_START"
        const val ACTION_STOP = "com.tander.app.CALL_FOREGROUND_STOP"
        const val ACTION_CONNECTED = "com.tander.app.CALL_FOREGROUND_CONNECTED"
        const val ACTION_HANGUP = "com.tander.app.CALL_FOREGROUND_HANGUP"

        fun start(context: Context, callerName: String, callType: String) {
            val intent = Intent(context, CallForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_CALLER_NAME, callerName)
                putExtra(EXTRA_CALL_TYPE, callType)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /** Switch the notification from "Connecting…" to a running timer once
         *  the peer is actually in the room. Idempotent. */
        fun markConnected(context: Context) {
            context.startService(
                Intent(context, CallForegroundService::class.java).apply {
                    action = ACTION_CONNECTED
                }
            )
        }

        fun stop(context: Context) {
            context.startService(
                Intent(context, CallForegroundService::class.java).apply {
                    action = ACTION_STOP
                }
            )
        }
    }

    private var callerName: String = "Caller"
    private var callType: String = "audio"
    // 0L = not connected yet (show "Connecting…"); else chronometer base.
    private var connectedAtMillis: Long = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "Caller"
                callType = intent.getStringExtra(EXTRA_CALL_TYPE) ?: "audio"
                connectedAtMillis = 0L
                startInForeground()
            }
            ACTION_CONNECTED -> {
                if (connectedAtMillis == 0L) {
                    connectedAtMillis = System.currentTimeMillis()
                    // Already foreground — just update the existing notification.
                    NotificationManagerCompat.from(this)
                        .notify(NOTIFICATION_ID, buildNotification())
                }
            }
            ACTION_HANGUP -> {
                Log.i(TAG, "hang up tapped on notification")
                // Drives backend end + Twilio disconnect + UI clear; the
                // resulting onDisconnected calls stop() which tears us down.
                TwilioCallManager.getInstance(applicationContext).hangUpFromNotification()
            }
            ACTION_STOP -> {
                Log.i(TAG, "stop requested")
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            else -> {
                Log.w(TAG, "unknown action: ${intent?.action}")
                stopSelf()
            }
        }
        // Sticky redelivery is wrong here — if Android kills us, we don't want
        // a stale "in call" notification revived without a real call backing it.
        return START_NOT_STICKY
    }

    private fun startInForeground() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ — foregroundServiceType bitmask must be a subset of
            // the manifest <service> declaration. Video adds CAMERA + MICROPHONE
            // ONLY if camera permission is actually granted (declaring CAMERA
            // without the permission throws SecurityException).
            var type = android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
            if (callType == "video" && hasCameraPermission()) {
                type = type or
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA or
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            }
            startForeground(NOTIFICATION_ID, notification, type)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        Log.i(TAG, "started foreground for $callerName ($callType)")
    }

    private fun hasCameraPermission(): Boolean =
        androidx.core.content.ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.CAMERA,
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED

    private fun buildNotification(): Notification {
        // Tapping the notification body returns to the app.
        val tapIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val tapPending = tapIntent?.let {
            PendingIntent.getActivity(
                this, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        // Hang Up action → ACTION_HANGUP back to this service.
        val hangUpPending = PendingIntent.getService(
            this, 1,
            Intent(this, CallForegroundService::class.java).apply { action = ACTION_HANGUP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val person = Person.Builder().setName(callerName).setImportant(true).build()
        val connected = connectedAtMillis != 0L

        val builder = NotificationCompat.Builder(this, TanderApplication.CHANNEL_CALL_ONGOING)
            .setSmallIcon(android.R.drawable.sym_call_outgoing)
            .setStyle(NotificationCompat.CallStyle.forOngoingCall(person, hangUpPending))
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            // Show full content + the Hang Up button on the lock screen, so a
            // user who set the phone down mid-call can still end it.
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColorized(true)
            .setColor(0xFF1F8A4C.toInt()) // call-green, matches in-app island
            .setContentIntent(tapPending)
            .setContentText(
                if (connected) "On a call with $callerName"
                else "Connecting to $callerName…",
            )

        if (connected) {
            // CallStyle shows a live MM:SS timer when chronometer is enabled.
            builder.setUsesChronometer(true).setWhen(connectedAtMillis).setShowWhen(true)
        } else {
            builder.setShowWhen(false)
        }

        return builder.build()
    }
}
