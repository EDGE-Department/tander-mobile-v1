/// Call lifecycle constants — timeouts, STOMP destinations, fallback STUN servers.
///
/// Mirrors the web's `call.types.ts` constants and Flutter's original
/// `CallConfig` values exactly.
library;

// ---------------------------------------------------------------------------
// Timeouts
// ---------------------------------------------------------------------------

/// Call lifecycle timeouts.
///
/// - [initiating] — Max wait for the call to start ringing on the remote device.
/// - [ringing] — Max ringing duration before auto-dismissing the incoming overlay.
/// - [connecting] — Max wait for ICE to reach "connected" after SDP exchange.
/// - [maxCall] — Absolute hard ceiling on a single call (4 hours).
/// - [endedDisplay] — How long the "Call ended" screen stays visible before reset.
abstract final class CallTimeouts {
  static const Duration initiating = Duration(seconds: 60);
  static const Duration ringing = Duration(seconds: 60);
  static const Duration connecting = Duration(seconds: 30);
  static const Duration maxCall = Duration(hours: 4);
  static const Duration endedDisplay = Duration(seconds: 3);
}

// ---------------------------------------------------------------------------
// STOMP destinations
// ---------------------------------------------------------------------------

/// STOMP destinations for call signaling — matches web's CALL_DESTINATIONS.
abstract final class CallDestinations {
  // Client → Server
  static const String sendOffer = '/app/webrtc.offer';
  static const String sendAnswer = '/app/webrtc.answer';
  static const String sendIce = '/app/webrtc.ice';
  static const String sendHangup = '/app/webrtc.hangup';
  static const String sendMediaState = '/app/webrtc.media-state';
  static const String sendRingAck = '/app/webrtc.ring-ack';

  // Server → Client (subscribe)
  static String callEventsTopic(String userId) => '/topic/calls.$userId';
  static String callEventsQueue(String userId) => '/user/$userId/queue/calls';
  static String roomTopic(String roomId) => '/topic/call/$roomId';
  static String webrtcQueue(String userId) => '/user/$userId/queue/webrtc';
  static String webrtcTopic(String userId) => '/topic/webrtc.$userId';
}

// ---------------------------------------------------------------------------
// Fallback STUN servers
// ---------------------------------------------------------------------------

/// Public Google STUN servers — used when the backend ICE server fetch fails.
const List<Map<String, Object>> fallbackIceServers = [
  {'urls': 'stun:stun.l.google.com:19302'},
  {'urls': 'stun:stun1.l.google.com:19302'},
];

// ---------------------------------------------------------------------------
// Audio constraints
// ---------------------------------------------------------------------------

/// Media constraints matching the web's AUDIO_CONSTRAINTS and VIDEO_CONSTRAINTS.
abstract final class CallMediaConstraints {
  static const Map<String, Object> audioConstraints = {
    'echoCancellation': true,
    'noiseSuppression': true,
    'autoGainControl': true,
    'sampleRate': 48000,
    'channelCount': 1,
  };

  static const Map<String, Object> videoConstraints = {
    'minWidth': '320',
    'minHeight': '240',
    'minFrameRate': '15',
    'width': '640',
    'height': '480',
    'frameRate': '24',
    'facingMode': 'user',
  };
}
