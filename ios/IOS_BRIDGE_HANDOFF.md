# iOS Twilio Call/Video Bridge — Handoff (for Claude Code on the Mac)

**Status: SOURCE-COMPLETE, UNCOMPILED.** Written on a Windows machine (no Swift
compiler), reviewed against the Twilio Video iOS 5.x API but never built. Expect
**1–3 iteration rounds** on the Mac. You (Mac Claude Code) have authority to fix
compile errors and behavior bugs directly — don't just relay them. Calibrated
expectation: it will probably compile within a fix or two; the real risk is the
**CallKit audio path** (see §Risks).

This file is the task state. Read it fully before touching anything.

## What this is
Brings iOS to call/video parity with the existing **Android** implementation
(Twilio Video Android 7.10.4). The Dart layer is 100% platform-agnostic and
already shipped; only the iOS native media layer was missing. iOS *already* had
the hard part (PushKit→CallKit→accept→Dart incoming-call plumbing via
`flutter_callkit_incoming`) + Info.plist mic/camera/`audio`+`voip` modes.

## Files (all new/changed in this work)
- `ios/Runner/TwilioVideoBridge.swift` — **NEW.** Media singleton, mirrors Android `TwilioCallManager.kt` for the MethodChannel API contract (identical method/event names + arg keys); implementation details differ (e.g., HashMap vs Swift dict, Android save/restores audio state on disconnect, iOS does not). Owns the `Room`, tracks, `DefaultAudioDevice`, the `tander/twilio_call` MethodChannel handler, and emits events to Dart.
- `ios/Runner/TwilioVideoViewFactory.swift` — **NEW.** `FlutterPlatformViewFactory` for viewType `tander/twilio_video_view`; hosts Twilio `VideoView`.
- `ios/Runner/AppDelegate.swift` — **PATCHED.** Registers the channel + factory; conforms to `CallkitIncomingAppDelegate`; shared `tanderDeterministicUUID(from:)`.
- `ios/Podfile` — `pod 'TwilioVideo', '~> 5.11'`.
- `lib/features/calls/v2/v2_in_call_screen.dart` — `AndroidView`→`_twilioVideoView` helper (UiKitView on iOS). **Dart analyzes clean.**
- Info.plist + `Runner.entitlements` — **no change needed** (mic/camera/`voip`/`audio` + `aps-environment` already present).

## Build (Mac)
```
flutter pub get
cd ios && pod install        # pulls TwilioVideo 5.11
open Runner.xcworkspace      # build + run on a REAL iPhone (Simulator has no camera)
```
Prereqs the USER must supply (NOT in this repo): Apple Developer account ($99/yr),
signing cert/provisioning, a physical iPhone for TestFlight. Do not commit any
Twilio tokens or signing material.

## ⚠️ Risk #1 — read first: the UUID assumption (most likely first real bug)
`TwilioVideoBridge.connect()` derives the Twilio `ConnectOptions.uuid` from
`roomName` via `tanderDeterministicUUID(from:)`, **assuming `roomName` == the
backend `roomId`** that `AppDelegate` used to mint the CallKit call UUID. If they
differ, CallKit's audio session won't bind to the Room → **mic dead when answered
from the lock screen**. If you see that symptom, fix is in `TwilioVideoBridge.connect()`
(~where `connectUUID` is computed) — pass the real `roomId` through the Dart
`connect` call args instead of reusing `roomName`. Verify `roomName`/`roomId`
equality against the backend before assuming it's broken.

## CallKit audio-session model (why AppDelegate looks the way it does)
The `flutter_callkit_incoming` plugin **owns the sole `CXProvider`/CXProviderDelegate** —
do NOT create another. AppDelegate conforms to the plugin's `CallkitIncomingAppDelegate`
protocol; on `didActivateAudioSession` it sets `TwilioVideoBridge.shared.audioDevice.isEnabled = true`
(and false on deactivate). We never call `AVAudioSession.setActive` ourselves —
CallKit owns activation. **Conforming to that protocol disables the plugin's
auto-fulfill**, so AppDelegate MUST call `action.fulfill()` in onAccept/onDecline/onEnd
(it does). `callData.configureAudioSession=false` (AppDelegate) keeps the plugin
from fighting Twilio over the session.

## MethodChannel contract `tander/twilio_call` (verify the Swift emits these names)
Dart→native methods: `connect{roomName,twilioToken,isAudioOnly,peerName}`,
`disconnect`, `toggleMute{muted}`, `setSpeakerphone{on}`, `setVideoEnabled{enabled}`.
Native→Dart events (exact names — Dart depends on them): `roomConnected{roomSid,roomName,localParticipantSid}`,
`roomConnectFailure{code,message}`, `roomReconnecting{message}`, `roomReconnected`,
`roomDisconnected{code,message}`, `participantConnected{participantSid,identity}`,
`participantDisconnected{participantSid,identity}`, `audioTrackSubscribed{participantSid,trackSid}`,
`remoteVideoTrackSubscribed{participantSid,trackSid}`, `remoteVideoTrackUnsubscribed{participantSid}`,
`remoteVideoEnabled{participantSid}`, `remoteVideoDisabled{participantSid}`,
`localVideoTrackPublished`, `networkQualityChanged{participantSid,level}`, `hangUpRequested`.
PlatformView `tander/twilio_video_view` creationParams: `{kind:"local"|"remote", participantSid:String?}`.

## Verify checklist (runnable; failure → where to look)
1. **`pod install` succeeds** → TwilioVideo 5.11 resolves. If it fails on iOS deploy target, confirm Podfile `platform :ios, '13.0'` (5.x supports it).
2. **Xcode builds.** Any compile error is almost certainly an API-name/optionality nit — fix in place. (Review verified the API names against 5.x docs, but it was static analysis.)

   Suspect lines (most → least likely), per static review against Twilio Video iOS 5.11 docs:
   - **TIER 1 — highest risk:** `TwilioVideoBridge.swift:184` — `DefaultAudioDevice.DefaultAVAudioSessionConfigurationBlock()` call site uses unusual class-function-call syntax. Verify whether 5.11 exposes this as a class function returning a block, or as an instance property. If compile fails here, the fix is likely accessing `.audioSessionConfigurationBlock` as a property instead.
   - **TIER 2 — medium risk:** `TwilioVideoViewFactory.swift:31` — `VideoView(frame: frame, delegate: nil)` two-arg init. Verify this is the designated initializer in 5.11 — the bare `init(frame:)` may be the canonical signature with delegate set as a property.
   - TIER 3 (low — confirmed via API docs): `TwilioVideoSDK.connect(options:delegate:)`, `LocalVideoTrack(source:enabled:name:)`, `CameraSource(delegate:)`, `CameraSource.captureDevice(position:)`, `Room.Listener` / `RemoteParticipant.Listener` delegate selectors — all verified against Twilio 5.x docs.

   **Compile confidence:** MEDIUM-HIGH that the bridge compiles. Expect 0-2 errors on lines 184 and 31. All other API surface verified against Twilio Video iOS 5.11 public docs via web search.
3. **Outgoing call: Android answers → iPhone hears + is heard.** No audio → §Risk #1 (UUID) or `audioDevice.isEnabled` not toggling (add a log in AppDelegate `didActivateAudioSession`).
4. **Video renders both ways.** Remote blank → check `remoteVideoTrackSubscribed` fires + the PlatformView's `attachRemoteVideo(participantSid:)` matches the `participantSid` Dart passes. Self-view blank → `localVideoTrackPublished` + `attachLocalVideo`.
5. **Lock-screen answer keeps audio.** Dead → §Risk #1, definitively.
6. **Mute / speaker / camera-toggle / hang-up** map to the 5 methods.

## Known P2 (deferred — don't fix until a device test shows they matter)
- `TwilioVideoBridge.releaseLocalTracks()` nils tracks without first `removeRenderer` on mounted views (Twilio's teardown is usually clean).
- `pendingLocalViews` can accumulate on audio-only calls (only drained in the `!isAudioOnly` connect branch). Clear it on disconnect if it bites.

## Already investigated (do NOT re-launch these)
Five agents + multiple advisor passes already covered: the full Android contract
extraction, the Twilio iOS 5.x SDK API (all delegate selectors / builder props /
`DefaultAVAudioSessionConfigurationBlock()` verified correct), the Flutter iOS
PlatformView pattern, the `flutter_callkit_incoming` audio-session hooks. **Note:** protocol integration was researched against 2.5.8 docs; pubspec pins 2.0.4+1. The `CallkitIncomingAppDelegate` protocol exists in both versions — verify the protocol signature on first Mac build; if `onEvent` callback shape differs from what `AppDelegate.swift` conforms to, adjust the conformance there, and a full code review of the three Swift files (no P0s; the
two P1 fixes are already applied). Start from compile, not from research.

