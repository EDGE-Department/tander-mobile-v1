package com.tander.tander_flutter_v3

import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import com.twilio.video.VideoScaleType
import com.twilio.video.VideoTextureView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * PlatformView factory for Twilio video. Renders a [VideoTextureView]
 * (TextureView-based, so Flutter's default Texture Layer Hybrid Composition
 * handles it via a plain `AndroidView` — no full Hybrid Composition needed).
 *
 * creationParams: `{ "kind": "remote"|"local", "participantSid": String? }`.
 * The view registers itself with [TwilioCallManager], which adds it as a sink
 * to the matching track; on dispose it's detached + released.
 */
class TwilioVideoViewFactory(private val appContext: Context) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = (args as? Map<String, Any?>) ?: emptyMap()
        val kind = params["kind"] as? String ?: "remote"
        val participantSid = params["participantSid"] as? String
        return TwilioVideoPlatformView(appContext, kind, participantSid)
    }
}

private class TwilioVideoPlatformView(
    context: Context,
    private val kind: String,
    private val participantSid: String?,
) : PlatformView {

    private val videoView = VideoTextureView(context).apply {
        // Cover/crop so the call view is full-bleed, not letterboxed.
        setVideoScaleType(VideoScaleType.ASPECT_FILL)
        // Selfie convention: mirror my own preview, never the remote peer.
        setMirror(kind == "local")
    }

    init {
        val mgr = TwilioCallManager.getInstance(context)
        if (kind == "local") {
            mgr.attachLocalVideo(videoView)
        } else if (participantSid != null) {
            mgr.attachRemoteVideo(participantSid, videoView)
        }
        Log.i("TwilioVideoView", "created kind=$kind sid=$participantSid")
    }

    override fun getView(): View = videoView

    override fun dispose() {
        val mgr = TwilioCallManager.getInstance(videoView.context)
        mgr.detachVideo(if (kind == "local") null else participantSid, videoView)
        // Stop frames + detach from parent. VideoTextureView (unlike the
        // SurfaceView-based VideoView) has no release() — its SurfaceTexture
        // is freed when the TextureView detaches from the window.
        (videoView.parent as? ViewGroup)?.removeView(videoView)
        Log.i("TwilioVideoView", "disposed kind=$kind sid=$participantSid")
    }
}
