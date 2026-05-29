package com.tander.tander_flutter_v3

import android.content.Intent
import android.content.pm.ActivityInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tander.app/orientation"
    private val COLD_START_CHANNEL = "com.tander.app/coldstart"

    companion object {
        private const val ACTION_CALL_ACCEPT =
            "com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT"

        // Set when the Activity is (re)launched via the CallKit Accept action.
        // On a cold start the plugin's onEvent fires before any Dart listener
        // subscribes (broadcast stream → missed), and activeCalls() reports the
        // call as NOT accepted. The launch-intent action is the only reliable
        // "user accepted" signal. Dart consumes this once on boot.
        @Volatile
        var pendingColdStartAccept: Boolean = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Orientation channel (pre-existing — call screens lock portrait).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "lockPortrait" -> {
                        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                        result.success(null)
                    }
                    "unlockOrientation" -> {
                        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Phase 5 — Twilio Programmable Video MethodChannel.
        val twilioChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TwilioCallManager.METHOD_CHANNEL,
        )
        TwilioCallManager.getInstance(applicationContext).attachChannel(twilioChannel)

        // Phase 5 Stage 3 — Twilio video PlatformView (VideoTextureView via
        // Texture Layer Hybrid Composition; plain AndroidView on the Dart side).
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "tander/twilio_video_view",
            TwilioVideoViewFactory(applicationContext),
        )

        // Cold-start CallKit accept — Dart consumes this once on boot (after the
        // session is authenticated) to drive the v2 accept + Twilio connect.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COLD_START_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeAccept" -> {
                        val v = pendingColdStartAccept
                        pendingColdStartAccept = false
                        result.success(v)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        captureCallKitIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        captureCallKitIntent(intent)
    }

    private fun captureCallKitIntent(launchIntent: Intent?) {
        if (launchIntent?.action == ACTION_CALL_ACCEPT) {
            pendingColdStartAccept = true
        }
    }
}
