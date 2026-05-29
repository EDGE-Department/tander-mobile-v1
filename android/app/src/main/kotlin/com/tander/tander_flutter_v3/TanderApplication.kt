package com.tander.tander_flutter_v3

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.app.FlutterApplication

/**
 * Custom Application subclass for the Flutter app.
 *
 * Owns one job that MainActivity cannot: creating notification channels
 * BEFORE any push can arrive. FCM can deliver a data-only `incoming_call`
 * to a cold-launched process — at that moment `MainActivity.onCreate` has
 * not yet run, but `Application.onCreate` has, by Android's contract.
 * Channels created here are guaranteed to exist when the FCM-triggered
 * incoming-call notification needs to render. Master plan rev 3 R10.
 *
 * Notification channels are mutable only via uninstall/reinstall once
 * created — channel IDs are part of the wire contract. Don't rename
 * without thought.
 */
class TanderApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        // API 26+ required for channels; minSdk is 26 so this is always true.
        // The version guard is kept defensively.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Legacy active-call foreground channel — IMPORTANCE_LOW. Kept so the
        // channel ID stays registered for any old code path, but the live call
        // notification now uses CHANNEL_CALL_ONGOING below (LOW can't show the
        // system call chip / CallStyle treatment on API 31+).
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_CALL_FOREGROUND,
                "Active call",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Ongoing-call indicator while you are in a Tander call."
                setShowBadge(false)
            }
        )

        // Ongoing-call channel — IMPORTANCE_DEFAULT is the documented minimum
        // for the Notification.CallStyle template + the system ongoing-call
        // chip on API 31+. Channel importance is immutable once created, so
        // this is a NEW id (can't just raise CHANNEL_CALL_FOREGROUND). Sound +
        // vibration are suppressed: the user is already in the call, we don't
        // want a ding when the foreground notification posts/updates.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_CALL_ONGOING,
                "Ongoing call",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Controls (timer, hang up) while you are in a Tander call."
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
        )

        // Incoming-call channel — IMPORTANCE_HIGH so it surfaces over
        // other content. Note: flutter_callkit_incoming creates its own
        // channel for the CallKit-style ring UI; this one is a fallback
        // for any custom incoming-call notification we render ourselves.
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_INCOMING_CALL,
                "Incoming calls",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Notifies you of incoming Tander calls."
                setShowBadge(true)
            }
        )
    }

    companion object {
        const val CHANNEL_CALL_FOREGROUND = "tander.call.foreground"
        const val CHANNEL_CALL_ONGOING = "tander.call.ongoing"
        const val CHANNEL_INCOMING_CALL = "tander.call.incoming"
    }
}
