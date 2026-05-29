import Flutter
import UIKit
import PushKit
import CallKit
import AVFAudio
import UserNotifications
import flutter_callkit_incoming
import TwilioVideo

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
  /// Controls whether the app is locked to portrait orientation.
  /// When true, only portrait orientations are allowed (for liveness/ID verification screens).
  static var isPortraitLocked: Bool = false

  /// Strong reference to the PushKit registry. MUST be an instance property —
  /// a local `let` is deallocated when didFinishLaunchingWithOptions returns
  /// and PushKit token / push callbacks then never fire.
  private var voipRegistry: PKPushRegistry?

  /// Strong reference to the cold-start fallback CXProvider. A local `let`
  /// can be released by ARC before `reportNewIncomingCall`'s async completion
  /// fires, which would violate the PushKit contract and let iOS terminate the
  /// app on a cold-start VoIP push. Held until the completion runs.
  private var fallbackProvider: CXProvider?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ── Twilio Video media bridge (iOS parity with Android) ──────────────
    // Register the `tander/twilio_call` MethodChannel + `tander/twilio_video_view`
    // PlatformView. The Dart side is platform-agnostic; this completes the iOS
    // half. See TwilioVideoBridge.swift / TwilioVideoViewFactory.swift.
    if let registrar = self.registrar(forPlugin: "tander-twilio-video") {
      let twilioChannel = FlutterMethodChannel(
        name: TwilioVideoBridge.methodChannelName,
        binaryMessenger: registrar.messenger())
      TwilioVideoBridge.shared.attachChannel(twilioChannel)
      registrar.register(TwilioVideoViewFactory(), withId: "tander/twilio_video_view")
    }

    // Required for flutter_local_notifications and firebase_messaging
    // to show notifications while app is in foreground.
    UNUserNotificationCenter.current().delegate = self

    // Register for VoIP pushes via PushKit. Apple delivers a credential to
    // pushRegistry(_:didUpdate:for:) below, which we forward to the
    // flutter_callkit_incoming plugin so the Dart side can register the
    // token with the backend.
    self.voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    self.voipRegistry?.delegate = self
    self.voipRegistry?.desiredPushTypes = [.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Called by iOS to determine which orientations are supported.
  /// This is the key method that enforces portrait lock on iPhones and iPads.
  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    if AppDelegate.isPortraitLocked {
      // Lock to portrait only (works on both iPhone and iPad)
      return .portrait
    }
    // Default: allow all orientations
    return .all
  }

  @available(iOS 16.0, *)
  private func setNeedsUpdateOfSupportedInterfaceOrientations() {
    window?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
  }

  // MARK: - PKPushRegistryDelegate

  /// Called when PushKit assigns a VoIP token. Forwards the token to
  /// flutter_callkit_incoming, which exposes it to Dart via
  /// `getDevicePushTokenVoIP()` and emits `actionDidUpdateDevicePushTokenVoip`.
  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let tokenParts = pushCredentials.token.map { String(format: "%02.2hhx", $0) }
    let token = tokenParts.joined()
    NSLog("[AppDelegate] VoIP token: \(token)")

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  /// Called when a VoIP push arrives (foreground, background, or cold-start).
  ///
  /// Apple's PushKit contract (iOS 13+): every VoIP push delivered MUST be
  /// reported to CallKit via `reportNewIncomingCall` before the completion
  /// handler fires, or iOS will terminate the app. There is no "ignore"
  /// option — even a cancel push has to be reported, then immediately ended.
  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let data = payload.dictionaryPayload
    let pushType = data["type"] as? String ?? "incoming_call"
    let callerId = data["callerId"] as? String ?? ""
    let callerName = data["callerName"] as? String ?? "Unknown"
    let callerPhoto = data["callerPhoto"] as? String
    let callType = data["callType"] as? String ?? "voice"
    let roomId = normalizedRoomIdentifier(from: data, fallback: callerId)
    let isVideo = callType == "video"

    // CallKit's plugin does `UUID(uuidString: data.uuid)!` — a force-unwrap
    // that crashes on non-UUID strings. Backend roomId is not a UUID, so
    // fold it into a deterministic UUID. Same roomId always yields the same
    // UUID, so subsequent cancel pushes match the original incoming call.
    // Same helper the Twilio bridge uses for ConnectOptions.uuid, so the
    // CallKit call UUID and the Twilio Room UUID match (shared source of truth
    // in TwilioVideoBridge.swift).
    let uuid = roomId.isEmpty ? UUID().uuidString : tanderDeterministicUUID(from: roomId)

    NSLog("[AppDelegate] VoIP push: type=\(pushType), caller=\(callerName), roomId=\(roomId), uuid=\(uuid)")

    // Cold-start safety net: on a fresh launch from a VoIP push, the
    // Flutter engine and the plugin may not have finished initialising. If
    // sharedInstance is nil we MUST still report a call to CallKit, or iOS
    // kills the app. Use CXProvider directly with a minimal CXCallUpdate.
    guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
      NSLog("[AppDelegate] CRITICAL: Plugin nil — minimal CXProvider report to satisfy PushKit contract")
      // Hold a strong reference on self so ARC cannot release the provider
      // before reportNewIncomingCall's async completion fires. A local `let`
      // would be deallocated as soon as this function returns (the completion
      // closure does not capture it), which violates the PushKit contract and
      // can let iOS terminate the app on a cold-start VoIP push.
      let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "Tander"))
      self.fallbackProvider = provider
      let update = CXCallUpdate()
      update.remoteHandle = CXHandle(type: .generic, value: callerName)
      let callUUID = UUID(uuidString: uuid) ?? UUID()
      provider.reportNewIncomingCall(with: callUUID, update: update) { [weak self] error in
        if let error = error { NSLog("[AppDelegate] Minimal call report error: \(error)") }
        self?.fallbackProvider = nil
        completion()
      }
      return
    }

    // Cancel push: still report a call (Apple contract), then end it
    // immediately so the UI doesn't show.
    if pushType == "call_cancelled" || pushType == "call_ended" {
      NSLog("[AppDelegate] VoIP cancel/end push, reporting+ending: \(uuid)")
      let cancelData = flutter_callkit_incoming.Data(id: uuid, nameCaller: callerName, handle: "", type: 0)
      cancelData.duration = 0
      plugin.showCallkitIncoming(cancelData, fromPushKit: true) {
        plugin.endCall(cancelData)
        completion()
      }
      return
    }

    // Incoming call. Build full call data and present CallKit UI.
    let callData = flutter_callkit_incoming.Data(id: uuid, nameCaller: callerName, handle: roomId, type: isVideo ? 1 : 0)
    callData.avatar = callerPhoto ?? ""
    callData.extra = [
      "callerId": callerId,
      "roomId": roomId,
      "callType": callType,
    ]
    callData.duration = 45000
    callData.handleType = "generic"
    callData.supportsVideo = true
    callData.maximumCallGroups = 1
    callData.maximumCallsPerCallGroup = 1
    // Twilio Video manages its own audio session — we don't drive it here.
    callData.audioSessionMode = isVideo ? "videoChat" : "voiceChat"
    callData.audioSessionActive = false
    callData.configureAudioSession = false
    callData.ringtonePath = "system_ringtone_default"

    plugin.showCallkitIncoming(callData, fromPushKit: true) {
      completion()
    }
  }

  // MARK: - UUID normalization for CallKit

  /// Picks the best room/call identifier from a VoIP payload. Backend has
  /// historically used a few different keys — keep the resolution forgiving.
  private func normalizedRoomIdentifier(from payload: [AnyHashable: Any], fallback: String) -> String {
    if let roomId = payload["roomId"] as? String, !roomId.isEmpty { return roomId }
    if let roomName = payload["roomName"] as? String, !roomName.isEmpty { return roomName }
    if let roomUnderscore = payload["room_id"] as? String, !roomUnderscore.isEmpty { return roomUnderscore }
    return fallback
  }

  // (UUID derivation lives in TwilioVideoBridge.swift as the file-scope
  // `tanderDeterministicUUID(from:)` so CallKit + Twilio share one source.)

  // MARK: - CallkitIncomingAppDelegate
  //
  // Conforming to this protocol makes flutter_callkit_incoming STOP
  // auto-fulfilling CallKit actions — we MUST call action.fulfill() in each of
  // onAccept/onDecline/onEnd or the action hangs in CallKit. The Dart event
  // stream still fires independently (V2CallkitListener drives accept/decline/
  // end + Twilio connect/disconnect), so these stay thin: fulfill, let Dart run.
  // The PushKit handler above is unaffected by this conformance.

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    // Fulfill immediately. Dart's accept handler calls TwilioNativeBridge.connect
    // via the plugin's accept event; the bridge installs its audioDevice BEFORE
    // connecting, so didActivateAudioSession arrives after connect and enables
    // the device. Do NOT reorder to fulfill-after-connect.
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    // Native end (CallKit UI). Dart's end event drives backend-end + Twilio
    // disconnect (idempotent), so just fulfill here.
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {
    // Unanswered timeout — plugin reports the ended call; nothing to fulfill.
  }

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    // CallKit activated the session → enable Twilio's audio device. We never
    // call AVAudioSession.setActive ourselves; CallKit owns the session.
    TwilioVideoBridge.shared.audioDevice.isEnabled = true
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    TwilioVideoBridge.shared.audioDevice.isEnabled = false
  }
}
