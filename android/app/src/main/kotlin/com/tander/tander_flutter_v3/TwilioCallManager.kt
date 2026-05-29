package com.tander.tander_flutter_v3

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import com.twilio.video.Camera2Capturer
import com.twilio.video.ConnectOptions
import com.twilio.video.LocalAudioTrack
import com.twilio.video.LocalVideoTrack
import com.twilio.video.NetworkQualityLevel
import com.twilio.video.RemoteAudioTrack
import com.twilio.video.RemoteAudioTrackPublication
import com.twilio.video.RemoteDataTrack
import com.twilio.video.RemoteDataTrackPublication
import com.twilio.video.RemoteParticipant
import com.twilio.video.RemoteVideoTrack
import com.twilio.video.RemoteVideoTrackPublication
import com.twilio.video.Room
import com.twilio.video.TwilioException
import com.twilio.video.Video
import com.twilio.video.VideoTextureView
import io.flutter.plugin.common.MethodChannel

/**
 * Singleton wrapping Twilio Programmable Video Android SDK (audio-only
 * for Stage 2; video tracks land in Stage 3 alongside the PlatformView
 * renderer).
 *
 * Lifecycle is driven from Flutter via MethodChannel `tander/twilio_call`.
 * Flutter → native: connect/disconnect/toggleMute/setSpeakerphone.
 * Native → Flutter: room and participant state changes.
 *
 * Audio focus + AudioManager mode is owned here, not by CallKit's plugin
 * — `flutter_callkit_incoming` is configured with
 * `configureAudioSession=false` so Twilio (us) drives the session.
 */
class TwilioCallManager private constructor(private val context: Context) {

    companion object {
        const val TAG = "TwilioCallManager"
        const val METHOD_CHANNEL = "tander/twilio_call"

        @Volatile private var instance: TwilioCallManager? = null

        fun getInstance(context: Context): TwilioCallManager =
            instance ?: synchronized(this) {
                instance ?: TwilioCallManager(context.applicationContext).also { instance = it }
            }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager: AudioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var methodChannel: MethodChannel? = null
    private var currentRoom: Room? = null
    private var localAudioTrack: LocalAudioTrack? = null
    private var localVideoTrack: LocalVideoTrack? = null
    private var cameraCapturer: Camera2Capturer? = null

    // Remote video tracks by participant sid + views waiting for a track that
    // hasn't been subscribed yet (defensive — the Flutter side gates the view
    // on the subscribe event, so this is normally empty).
    private val remoteVideoTracks = HashMap<String, RemoteVideoTrack>()
    private val pendingRemoteViews = HashMap<String, VideoTextureView>()

    // Saved audio state so we can restore on disconnect.
    private var savedAudioMode: Int = AudioManager.MODE_NORMAL
    private var savedSpeakerphoneOn: Boolean = false

    // -----------------------------------------------------------------
    // Channel binding — called from MainActivity.configureFlutterEngine
    // -----------------------------------------------------------------

    fun attachChannel(channel: MethodChannel) {
        this.methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "connect" -> {
                        val roomName = call.argument<String>("roomName")
                            ?: return@setMethodCallHandler result.error("ARG", "roomName required", null)
                        val token = call.argument<String>("twilioToken")
                            ?: return@setMethodCallHandler result.error("ARG", "twilioToken required", null)
                        val audioOnly = call.argument<Boolean>("isAudioOnly") ?: true
                        val peerName = call.argument<String>("peerName") ?: "Caller"
                        connect(roomName, token, audioOnly, peerName)
                        result.success(null)
                    }
                    "disconnect" -> { disconnect(); result.success(null) }
                    "toggleMute" -> {
                        val muted = call.argument<Boolean>("muted") ?: false
                        toggleMute(muted)
                        result.success(null)
                    }
                    "setSpeakerphone" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        audioManager.isSpeakerphoneOn = on
                        result.success(null)
                    }
                    "setVideoEnabled" -> {
                        val on = call.argument<Boolean>("enabled") ?: true
                        setVideoEnabled(on)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                Log.e(TAG, "MethodChannel call failed: ${call.method}", t)
                result.error("EXC", t.message, null)
            }
        }
    }

    // -----------------------------------------------------------------
    // Public API (called via MethodChannel)
    // -----------------------------------------------------------------

    fun connect(roomName: String, twilioToken: String, isAudioOnly: Boolean, peerName: String = "Caller") {
        if (currentRoom != null) {
            Log.w(TAG, "connect called while already in a room; ignoring")
            return
        }
        configureAudioForCall()

        // Bring up foreground service BEFORE Video.connect so the process is
        // protected from Android killing us mid-handshake if the user
        // backgrounds the app during ringing.
        CallForegroundService.start(context, peerName, if (isAudioOnly) "audio" else "video")

        localAudioTrack = LocalAudioTrack.create(context, true)
        val audioTracks = localAudioTrack?.let { listOf(it) } ?: emptyList()

        val builder = ConnectOptions.Builder(twilioToken)
            .roomName(roomName)
            .audioTracks(audioTracks)
            .enableAutomaticSubscription(true)

        // Stage 3 (B1): publish the front camera for video calls. Falls back to
        // audio-only if the camera is missing or permission is denied — keeping
        // it consistent with CallForegroundService, which only claims the CAMERA
        // foreground type when permission is granted.
        if (!isAudioOnly) {
            val videoTrack = createCameraVideoTrack()
            if (videoTrack != null) {
                localVideoTrack = videoTrack
                builder.videoTracks(listOf(videoTrack))
            } else {
                Log.w(TAG, "Camera unavailable/denied — connecting audio-only")
            }
        }

        Log.i(TAG, "connecting to room=$roomName audioOnly=$isAudioOnly " +
                "video=${localVideoTrack != null}")
        currentRoom = Video.connect(context, builder.build(), roomListener)
    }

    /** Create a front-camera [LocalVideoTrack], or null if unavailable/denied. */
    private fun createCameraVideoTrack(): LocalVideoTrack? {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "CAMERA permission not granted")
            return null
        }
        return try {
            val cameraId = frontCameraId() ?: run {
                Log.w(TAG, "No camera id available")
                return null
            }
            val capturer = Camera2Capturer(context, cameraId)
            cameraCapturer = capturer
            // Emit ONLY when the track really exists, so the Flutter self-view
            // PIP reflects "camera is live" — not merely "permission granted".
            LocalVideoTrack.create(context, true, capturer)?.also {
                invokeOnFlutter("localVideoTrackPublished", emptyMap<String, Any>())
            }
        } catch (t: Throwable) {
            Log.e(TAG, "createCameraVideoTrack failed", t)
            cameraCapturer = null
            null
        }
    }

    /** Prefer the front-facing camera; fall back to the first available. */
    private fun frontCameraId(): String? {
        return try {
            val cm = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val ids = cm.cameraIdList
            ids.firstOrNull { id ->
                cm.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING) ==
                    CameraCharacteristics.LENS_FACING_FRONT
            } ?: ids.firstOrNull()
        } catch (t: Throwable) {
            Log.e(TAG, "frontCameraId lookup failed", t)
            null
        }
    }

    private fun releaseLocalTracks() {
        localAudioTrack?.release()
        localAudioTrack = null
        localVideoTrack?.release()
        localVideoTrack = null
        cameraCapturer = null
        remoteVideoTracks.clear()
        pendingRemoteViews.clear()
    }

    // ─── Video renderer binding (Stage 3 B2/B3), called from the factory ───

    fun attachRemoteVideo(participantSid: String, view: VideoTextureView) {
        val track = remoteVideoTracks[participantSid]
        if (track != null) {
            track.addSink(view)
            Log.i(TAG, "attached remote video sink sid=$participantSid")
        } else {
            Log.w(TAG, "attachRemoteVideo: no track yet for sid=$participantSid; pending")
            pendingRemoteViews[participantSid] = view
        }
    }

    fun attachLocalVideo(view: VideoTextureView) {
        localVideoTrack?.addSink(view)
        Log.i(TAG, "attached local video sink (track=${localVideoTrack != null})")
    }

    fun detachVideo(participantSid: String?, view: VideoTextureView) {
        if (participantSid != null) {
            remoteVideoTracks[participantSid]?.removeSink(view)
            pendingRemoteViews.remove(participantSid)
        } else {
            localVideoTrack?.removeSink(view)
        }
    }

    fun disconnect() {
        Log.i(TAG, "disconnect called")
        currentRoom?.disconnect()
        // currentRoom is nulled in onDisconnected.
    }

    /**
     * Notification "Hang Up" entry point (from CallForegroundService).
     * Asks Dart to run the FULL hangup (backend end + UI clear) while its
     * state is still alive — reaches Dart whenever the Flutter engine is
     * attached (app foreground or merely backgrounded). Fallback for the
     * engine-detached case (Activity swiped away): force the Twilio
     * disconnect after a short grace period so the room never lingers.
     * Both disconnect paths are idempotent.
     */
    fun hangUpFromNotification() {
        invokeOnFlutter("hangUpRequested", emptyMap<String, Any>())
        mainHandler.postDelayed({
            if (currentRoom != null) {
                Log.i(TAG, "notification hangup fallback — forcing native disconnect")
                disconnect()
            }
        }, 2000)
    }

    fun toggleMute(muted: Boolean) {
        localAudioTrack?.enable(!muted)
    }

    /** Enable/disable the local camera mid-call (B4 toggle). The track stays
     * published; disabling just stops sending frames so the peer sees us as
     * camera-off (their client gets onVideoTrackDisabled). */
    fun setVideoEnabled(enabled: Boolean) {
        localVideoTrack?.enable(enabled)
        Log.i(TAG, "local video enabled=$enabled")
    }

    // -----------------------------------------------------------------
    // Audio focus + session mode (Twilio recommends MODE_IN_COMMUNICATION)
    // -----------------------------------------------------------------

    private fun configureAudioForCall() {
        savedAudioMode = audioManager.mode
        savedSpeakerphoneOn = audioManager.isSpeakerphoneOn
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.isSpeakerphoneOn = false
    }

    private fun restoreAudio() {
        audioManager.mode = savedAudioMode
        audioManager.isSpeakerphoneOn = savedSpeakerphoneOn
    }

    // -----------------------------------------------------------------
    // Room listener — forwards to Flutter via MethodChannel
    // -----------------------------------------------------------------

    private val roomListener = object : Room.Listener {
        override fun onConnected(room: Room) {
            Log.i(TAG, "Room ${room.name} (${room.sid}) connected, " +
                    "remote participants already present: ${room.remoteParticipants.size}")
            currentRoom = room
            invokeOnFlutter(
                "roomConnected",
                mapOf(
                    "roomSid" to room.sid,
                    "roomName" to room.name,
                    "localParticipantSid" to (room.localParticipant?.sid ?: ""),
                ),
            )
            // Snapshot: emit participantConnected for participants ALREADY
            // in the room when we joined. Twilio's `onParticipantConnected`
            // callback only fires for participants joining AFTER us, so the
            // callee path (phone joins after caller) would never see the
            // event for the caller without this. Mirrors web's
            // `activeRoom.participants.forEach(bindParticipant)`. Lessons
            // memory item #1.
            for (participant in room.remoteParticipants) {
                participant.setListener(participantListener)
                Log.i(TAG, "Emitting snapshot participantConnected for ${participant.identity}")
                invokeOnFlutter(
                    "participantConnected",
                    mapOf(
                        "participantSid" to participant.sid,
                        "identity" to participant.identity,
                    ),
                )
            }
            // Callee case: the caller is already in the room when we join, so
            // the call is "connected" now — start the notification timer.
            if (room.remoteParticipants.isNotEmpty()) {
                CallForegroundService.markConnected(context)
            }
        }

        override fun onConnectFailure(room: Room, twilioException: TwilioException) {
            Log.w(TAG, "Room connect failed: ${twilioException.message}")
            currentRoom = null
            releaseLocalTracks()
            restoreAudio()
            CallForegroundService.stop(context)
            invokeOnFlutter(
                "roomConnectFailure",
                mapOf("code" to twilioException.code, "message" to (twilioException.message ?: "")),
            )
        }

        override fun onReconnecting(room: Room, twilioException: TwilioException) {
            Log.i(TAG, "Room reconnecting: ${twilioException.message}")
            invokeOnFlutter(
                "roomReconnecting",
                mapOf("code" to twilioException.code, "message" to (twilioException.message ?: "")),
            )
        }

        override fun onReconnected(room: Room) {
            Log.i(TAG, "Room reconnected")
            invokeOnFlutter("roomReconnected", emptyMap<String, Any>())
        }

        override fun onDisconnected(room: Room, twilioException: TwilioException?) {
            Log.i(TAG, "Room disconnected: ${twilioException?.message ?: "no error"}")
            currentRoom = null
            releaseLocalTracks()
            restoreAudio()
            CallForegroundService.stop(context)
            invokeOnFlutter(
                "roomDisconnected",
                mapOf(
                    "code" to (twilioException?.code ?: 0),
                    "message" to (twilioException?.message ?: ""),
                ),
            )
        }

        override fun onParticipantConnected(room: Room, remoteParticipant: RemoteParticipant) {
            Log.i(TAG, "Participant ${remoteParticipant.identity} connected")
            remoteParticipant.setListener(participantListener)
            invokeOnFlutter(
                "participantConnected",
                mapOf(
                    "participantSid" to remoteParticipant.sid,
                    "identity" to remoteParticipant.identity,
                ),
            )
            // Caller case: peer just answered — start the notification timer.
            CallForegroundService.markConnected(context)
        }

        override fun onParticipantDisconnected(room: Room, remoteParticipant: RemoteParticipant) {
            Log.i(TAG, "Participant ${remoteParticipant.identity} disconnected")
            invokeOnFlutter(
                "participantDisconnected",
                mapOf(
                    "participantSid" to remoteParticipant.sid,
                    "identity" to remoteParticipant.identity,
                ),
            )
        }

        override fun onRecordingStarted(room: Room) { /* no-op */ }
        override fun onRecordingStopped(room: Room) { /* no-op */ }
    }

    // -----------------------------------------------------------------
    // Participant listener — track subscribe/unsubscribe stubs for Stage 3
    // -----------------------------------------------------------------

    private val participantListener = object : RemoteParticipant.Listener {
        override fun onAudioTrackPublished(p: RemoteParticipant, pub: RemoteAudioTrackPublication) {}
        override fun onAudioTrackUnpublished(p: RemoteParticipant, pub: RemoteAudioTrackPublication) {}
        override fun onAudioTrackSubscribed(
            p: RemoteParticipant,
            pub: RemoteAudioTrackPublication,
            audioTrack: RemoteAudioTrack,
        ) {
            invokeOnFlutter(
                "audioTrackSubscribed",
                mapOf("participantSid" to p.sid, "trackSid" to pub.trackSid),
            )
        }
        override fun onAudioTrackUnsubscribed(
            p: RemoteParticipant,
            pub: RemoteAudioTrackPublication,
            audioTrack: RemoteAudioTrack,
        ) {}
        override fun onAudioTrackSubscriptionFailed(
            p: RemoteParticipant,
            pub: RemoteAudioTrackPublication,
            twilioException: TwilioException,
        ) {}
        override fun onAudioTrackEnabled(p: RemoteParticipant, pub: RemoteAudioTrackPublication) {}
        override fun onAudioTrackDisabled(p: RemoteParticipant, pub: RemoteAudioTrackPublication) {}

        override fun onVideoTrackPublished(p: RemoteParticipant, pub: RemoteVideoTrackPublication) {}
        override fun onVideoTrackUnpublished(p: RemoteParticipant, pub: RemoteVideoTrackPublication) {}
        override fun onVideoTrackSubscribed(
            p: RemoteParticipant,
            pub: RemoteVideoTrackPublication,
            videoTrack: RemoteVideoTrack,
        ) {
            Log.i(TAG, "Remote video subscribed sid=${p.sid}")
            remoteVideoTracks[p.sid] = videoTrack
            // Bind any view created before the track arrived (race fallback).
            pendingRemoteViews.remove(p.sid)?.let { videoTrack.addSink(it) }
            invokeOnFlutter(
                "remoteVideoTrackSubscribed",
                mapOf("participantSid" to p.sid, "trackSid" to pub.trackSid),
            )
        }
        override fun onVideoTrackUnsubscribed(
            p: RemoteParticipant,
            pub: RemoteVideoTrackPublication,
            videoTrack: RemoteVideoTrack,
        ) {
            Log.i(TAG, "Remote video unsubscribed sid=${p.sid}")
            remoteVideoTracks.remove(p.sid)
            invokeOnFlutter(
                "remoteVideoTrackUnsubscribed",
                mapOf("participantSid" to p.sid),
            )
        }
        override fun onVideoTrackSubscriptionFailed(
            p: RemoteParticipant,
            pub: RemoteVideoTrackPublication,
            twilioException: TwilioException,
        ) {}
        override fun onVideoTrackEnabled(p: RemoteParticipant, pub: RemoteVideoTrackPublication) {
            Log.i(TAG, "Remote video enabled sid=${p.sid}")
            invokeOnFlutter("remoteVideoEnabled", mapOf("participantSid" to p.sid))
        }
        override fun onVideoTrackDisabled(p: RemoteParticipant, pub: RemoteVideoTrackPublication) {
            Log.i(TAG, "Remote video disabled sid=${p.sid}")
            invokeOnFlutter("remoteVideoDisabled", mapOf("participantSid" to p.sid))
        }

        // Data tracks — not used.
        override fun onDataTrackPublished(p: RemoteParticipant, pub: RemoteDataTrackPublication) {}
        override fun onDataTrackUnpublished(p: RemoteParticipant, pub: RemoteDataTrackPublication) {}
        override fun onDataTrackSubscribed(
            p: RemoteParticipant,
            pub: RemoteDataTrackPublication,
            dataTrack: RemoteDataTrack,
        ) {}
        override fun onDataTrackUnsubscribed(
            p: RemoteParticipant,
            pub: RemoteDataTrackPublication,
            dataTrack: RemoteDataTrack,
        ) {}
        override fun onDataTrackSubscriptionFailed(
            p: RemoteParticipant,
            pub: RemoteDataTrackPublication,
            twilioException: TwilioException,
        ) {}

        override fun onNetworkQualityLevelChanged(
            p: RemoteParticipant,
            networkQualityLevel: NetworkQualityLevel,
        ) {
            invokeOnFlutter(
                "networkQualityChanged",
                mapOf(
                    "participantSid" to p.sid,
                    "level" to networkQualityLevel.name,
                ),
            )
        }
    }

    // -----------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------

    private fun invokeOnFlutter(method: String, args: Map<String, Any>) {
        mainHandler.post {
            try {
                methodChannel?.invokeMethod(method, args)
            } catch (t: Throwable) {
                Log.w(TAG, "invokeMethod($method) failed", t)
            }
        }
    }
}
