import Flutter
import Foundation
import TwilioVideo

// ⚠️ WRITTEN ON WINDOWS, NOT YET COMPILED. iOS equivalent of Android's
// TwilioVideoViewFactory.kt. Registered for viewType `tander/twilio_video_view`
// in AppDelegate. creationParams = { kind: "local"|"remote", participantSid: String? }
// (identical to the Dart UiKitView/AndroidView contract). On iOS, UiKitView IS
// hybrid composition — no virtual-display/TLHC decision. There is no dispose()
// on FlutterPlatformView, so we detach the Twilio renderer in deinit to avoid
// the SDK retaining a stale view (the iOS analog of Android's detach-on-dispose).

final class TwilioVideoViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return TwilioVideoPlatformView(frame: frame, arguments: args)
  }

  // REQUIRED whenever creationParams is non-nil — must match the Dart
  // StandardMessageCodec() side, or args arrive nil (flutter/flutter#28124).
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

final class TwilioVideoPlatformView: NSObject, FlutterPlatformView {
  private let videoView: VideoView

  init(frame: CGRect, arguments args: Any?) {
    // Two-arg init (delegate: nil) is the form Twilio's quickstarts use; the
    // bare init(frame:) is unverified in 5.x (designated-initializer risk).
    videoView = VideoView(frame: frame, delegate: nil)
    super.init()

    videoView.contentMode = .scaleAspectFill // aspect-fill, matches Android ASPECT_FILL

    let params = args as? [String: Any] ?? [:]
    let kind = params["kind"] as? String ?? "remote"

    if kind == "local" {
      videoView.shouldMirror = true // mirror self-view only
      TwilioVideoBridge.shared.attachLocalVideo(videoView)
    } else {
      videoView.shouldMirror = false
      if let participantSid = params["participantSid"] as? String {
        TwilioVideoBridge.shared.attachRemoteVideo(participantSid: participantSid, videoView)
      }
    }
  }

  func view() -> UIView {
    return videoView
  }

  deinit {
    // No dispose() in the protocol — detach the renderer here so Twilio
    // doesn't keep rendering into a dead view.
    TwilioVideoBridge.shared.detachView(videoView)
  }
}
