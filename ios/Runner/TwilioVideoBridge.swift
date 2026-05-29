import AVFoundation
import Flutter
import Foundation
import TwilioVideo

// ─────────────────────────────────────────────────────────────────────────
// ⚠️ WRITTEN ON WINDOWS, NOT YET COMPILED. Expect a Mac/Xcode iteration round
// (esp. CallKit audio-session behavior). This mirrors the Android
// `TwilioCallManager.kt` media layer 1:1 — same `tander/twilio_call`
// MethodChannel method/event names + the `tander/twilio_video_view`
// PlatformView contract. The Dart layer is shared and unchanged.
//
// Division of responsibility (matches Android): this class does MEDIA ONLY —
// connect/disconnect/tracks/audio + raw Twilio events. Call PHASE state lives
// in Dart (V2ActiveCallNotifier). The audio SESSION is owned by CallKit via
// `flutter_callkit_incoming`; AppDelegate forwards didActivate/didDeactivate
// here to toggle `audioDevice.isEnabled` (see AppDelegate.swift).
// ─────────────────────────────────────────────────────────────────────────

/// Folds an arbitrary backend roomId into a deterministic UUID string — same
/// algorithm AppDelegate uses for the CallKit call UUID, so Twilio's
/// `ConnectOptions.uuid` matches the UUID reported to CallKit (required for
/// the CallKit audio session to bind to this Room).
func tanderDeterministicUUID(from roomId: String) -> String {
  if UUID(uuidString: roomId) != nil { return roomId }
  let bytes = Array(roomId.utf8)
  var hash = [UInt8](repeating: 0, count: 16)
  for (i, byte) in bytes.enumerated() { hash[i % 16] ^= byte }
  hash[6] = (hash[6] & 0x0F) | 0x40
  hash[8] = (hash[8] & 0x3F) | 0x80
  let hex = hash.map { String(format: "%02x", $0) }.joined()
  return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20))"
}

final class TwilioVideoBridge: NSObject {
  static let shared = TwilioVideoBridge()

  static let methodChannelName = "tander/twilio_call"

  /// Twilio audio device. CallKit (via the plugin) activates the AVAudioSession;
  /// we only flip `isEnabled` in AppDelegate's didActivate/didDeactivate.
  /// Swift bridges the Obj-C `+audioDevice` factory as `init()`, so writing
  /// `DefaultAudioDevice()` is correct (the importer hides the otherwise-unavailable
  /// `-init`).
  let audioDevice = DefaultAudioDevice()

  private var channel: FlutterMethodChannel?

  private var room: Room?
  private var localAudioTrack: LocalAudioTrack?
  private var localVideoTrack: LocalVideoTrack?
  private var camera: CameraSource?

  /// Remote video tracks by participant SID, so the PlatformView factory can
  /// attach a renderer when the view mounts (mirrors Android remoteVideoTracks).
  private var remoteVideoTracks: [String: RemoteVideoTrack] = [:]
  /// Views created before their track subscribed — attached on subscribe
  /// (mirrors Android pendingRemoteViews race fallback).
  private var pendingRemoteViews: [String: [VideoView]] = [:]
  /// Local self-view(s) created before the local track exists.
  private var pendingLocalViews: [VideoView] = []

  private var speakerOn = false

  private override init() {
    super.init()
    // Install our audio device once, before any connect (required for the
    // CallKit-owns-the-session model).
    TwilioVideoSDK.audioDevice = audioDevice
  }

  // MARK: - Channel wiring

  func attachChannel(_ channel: FlutterMethodChannel) {
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "connect":
      connect(
        roomName: args["roomName"] as? String ?? "",
        token: args["twilioToken"] as? String ?? "",
        isAudioOnly: args["isAudioOnly"] as? Bool ?? true,
        peerName: args["peerName"] as? String ?? "Caller")
      result(nil)
    case "disconnect":
      disconnect()
      result(nil)
    case "toggleMute":
      localAudioTrack?.isEnabled = !((args["muted"] as? Bool) ?? false)
      result(nil)
    case "setSpeakerphone":
      setSpeakerphone(on: (args["on"] as? Bool) ?? false)
      result(nil)
    case "setVideoEnabled":
      localVideoTrack?.isEnabled = (args["enabled"] as? Bool) ?? true
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Emit an event to Dart on the main thread (mirrors Android invokeOnFlutter).
  private func emit(_ method: String, _ arguments: [String: Any] = [:]) {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod(method, arguments: arguments)
    }
  }

  // MARK: - Connect / disconnect

  private func connect(roomName: String, token: String, isAudioOnly: Bool, peerName: String) {
    // Guard against double-connect (matches Android).
    guard room == nil else { return }

    // Swift bridges the Obj-C `+track` factory as `init?()`.
    guard let audio = LocalAudioTrack() else {
      NSLog("[TwilioVideoBridge] Failed to create LocalAudioTrack")
      emit("roomConnectFailure", ["code": -1, "message": "Failed to create local audio track"])
      return
    }
    localAudioTrack = audio

    var videoTracks: [LocalVideoTrack] = []
    if !isAudioOnly {
      if let video = createFrontCameraVideoTrack() {
        localVideoTrack = video
        videoTracks = [video]
        // Fires ONLY when the track truly exists — drives self-view PIP.
        emit("localVideoTrackPublished")
        // Attach any self-views that mounted before the track existed.
        for view in pendingLocalViews { video.addRenderer(view) }
        pendingLocalViews.removeAll()
      }
    }

    // The CallKit UUID is derived from the backend room id. Assumption to
    // VERIFY on device: the `roomName` passed here equals the backend roomId
    // used to mint the CallKit UUID in AppDelegate. If they differ, audio will
    // be dead on a lock-screen answer and this is where to fix it.
    let connectUUID = UUID(uuidString: tanderDeterministicUUID(from: roomName)) ?? UUID()

    let options = ConnectOptions(token: token) { builder in
      builder.roomName = roomName
      if let audio = self.localAudioTrack { builder.audioTracks = [audio] }
      builder.videoTracks = videoTracks
      builder.isAutomaticSubscriptionEnabled = true
      builder.uuid = connectUUID
    }
    room = TwilioVideoSDK.connect(options: options, delegate: self)
  }

  private func disconnect() {
    // Idempotent: room is nulled in roomDidDisconnect, not here, so repeat
    // calls are safe (matches Android).
    room?.disconnect()
  }

  private func releaseLocalTracks() {
    camera?.stopCapture()
    camera = nil
    localVideoTrack = nil
    localAudioTrack = nil
    remoteVideoTracks.removeAll()
    pendingRemoteViews.removeAll()
    pendingLocalViews.removeAll()
  }

  // MARK: - Camera

  private func createFrontCameraVideoTrack() -> LocalVideoTrack? {
    guard let frontDevice = CameraSource.captureDevice(position: .front) else { return nil }
    guard let source = CameraSource(delegate: self) else { return nil }
    guard let track = LocalVideoTrack(source: source, enabled: true, name: "camera") else { return nil }
    camera = source
    source.startCapture(device: frontDevice) { _, _, error in
      if let error = error { NSLog("[TwilioVideoBridge] camera start error: \(error)") }
    }
    return track
  }

  // MARK: - Speakerphone

  private func setSpeakerphone(on: Bool) {
    speakerOn = on
    audioDevice.block = { [weak self] in
      DefaultAudioDevice.DefaultAVAudioSessionConfigurationBlock()
      let session = AVAudioSession.sharedInstance()
      do {
        if self?.speakerOn == true {
          try session.setMode(.videoChat)
          try session.overrideOutputAudioPort(.speaker)
        } else {
          try session.setMode(.voiceChat)
          try session.overrideOutputAudioPort(.none)
        }
      } catch {
        NSLog("[TwilioVideoBridge] speaker route error: \(error)")
      }
    }
    audioDevice.block()
  }

  // MARK: - PlatformView attach/detach (called by TwilioVideoViewFactory)

  func attachLocalVideo(_ view: VideoView) {
    if let track = localVideoTrack {
      track.addRenderer(view)
    } else {
      pendingLocalViews.append(view)
    }
  }

  func attachRemoteVideo(participantSid: String, _ view: VideoView) {
    if let track = remoteVideoTracks[participantSid] {
      track.addRenderer(view)
    } else {
      pendingRemoteViews[participantSid, default: []].append(view)
    }
  }

  func detachView(_ view: VideoView) {
    localVideoTrack?.removeRenderer(view)
    for (_, track) in remoteVideoTracks { track.removeRenderer(view) }
    for (sid, views) in pendingRemoteViews {
      pendingRemoteViews[sid] = views.filter { $0 !== view }
    }
    pendingLocalViews.removeAll { $0 === view }
  }
}

// MARK: - RoomDelegate

extension TwilioVideoBridge: RoomDelegate {
  func roomDidConnect(room: Room) {
    emit("roomConnected", [
      "roomSid": room.sid,
      "roomName": room.name,
      "localParticipantSid": room.localParticipant?.sid ?? "",
    ])
    // Twilio does NOT redeliver already-present participants — snapshot them
    // (matches Android lesson #1).
    for participant in room.remoteParticipants {
      participant.delegate = self
      emit("participantConnected", [
        "participantSid": participant.sid ?? "",
        "identity": participant.identity,
      ])
    }
  }

  func roomDidFailToConnect(room: Room, error: Error) {
    self.room = nil
    releaseLocalTracks()
    emit("roomConnectFailure", ["code": (error as NSError).code, "message": error.localizedDescription])
  }

  func roomDidDisconnect(room: Room, error: Error?) {
    self.room = nil
    releaseLocalTracks()
    emit("roomDisconnected", ["code": (error as NSError?)?.code ?? 0, "message": error?.localizedDescription ?? ""])
  }

  func roomIsReconnecting(room: Room, error: Error) {
    emit("roomReconnecting", ["message": error.localizedDescription])
  }

  func roomDidReconnect(room: Room) {
    emit("roomReconnected")
  }

  func participantDidConnect(room: Room, participant: RemoteParticipant) {
    participant.delegate = self
    emit("participantConnected", [
      "participantSid": participant.sid ?? "",
      "identity": participant.identity,
    ])
  }

  func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
    emit("participantDisconnected", [
      "participantSid": participant.sid ?? "",
      "identity": participant.identity,
    ])
  }
}

// MARK: - RemoteParticipantDelegate

extension TwilioVideoBridge: RemoteParticipantDelegate {
  func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
    let sid = participant.sid ?? ""
    remoteVideoTracks[sid] = videoTrack
    // Attach any views that mounted before the track arrived.
    if let pending = pendingRemoteViews[sid] {
      for view in pending { videoTrack.addRenderer(view) }
      pendingRemoteViews[sid] = nil
    }
    emit("remoteVideoTrackSubscribed", ["participantSid": sid, "trackSid": publication.trackSid])
  }

  func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
    let sid = participant.sid ?? ""
    remoteVideoTracks[sid] = nil
    emit("remoteVideoTrackUnsubscribed", ["participantSid": sid])
  }

  func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
    emit("audioTrackSubscribed", ["participantSid": participant.sid ?? "", "trackSid": publication.trackSid])
  }

  func remoteParticipantDidEnableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
    emit("remoteVideoEnabled", ["participantSid": participant.sid ?? ""])
  }

  func remoteParticipantDidDisableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
    emit("remoteVideoDisabled", ["participantSid": participant.sid ?? ""])
  }

  func remoteParticipantNetworkQualityLevelDidChange(participant: RemoteParticipant, networkQualityLevel: NetworkQualityLevel) {
    emit("networkQualityChanged", [
      "participantSid": participant.sid ?? "",
      "level": String(describing: networkQualityLevel),
    ])
  }
}

// MARK: - CameraSourceDelegate

extension TwilioVideoBridge: CameraSourceDelegate {
  func cameraSourceDidFail(source: CameraSource, error: Error) {
    NSLog("[TwilioVideoBridge] camera source failed: \(error)")
  }
}
