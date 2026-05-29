/// Call domain types — sealed status hierarchy, enums, and value objects
/// for the peer-to-peer WebRTC calling system.
///
/// CRITICAL: [targetUserId] MUST be sent as [int] in all STOMP payloads.
/// The backend parses it as Integer; sending a String will silently fail.
library;

// ---------------------------------------------------------------------------
// Call status — sealed for exhaustive switching
// ---------------------------------------------------------------------------

/// State machine for a single call's lifecycle.
///
/// ```
/// idle → initiating → ringing → connecting → connected → ended
///                                    ↕
///                               reconnecting
/// ```
sealed class CallStatus {
  const CallStatus();
}

final class CallIdle extends CallStatus {
  const CallIdle();
}

final class CallInitiating extends CallStatus {
  const CallInitiating();
}

final class CallRinging extends CallStatus {
  const CallRinging();
}

final class CallConnecting extends CallStatus {
  const CallConnecting();
}

final class CallConnected extends CallStatus {
  const CallConnected();
}

final class CallReconnecting extends CallStatus {
  const CallReconnecting();
}

final class CallEnded extends CallStatus {
  const CallEnded();
}

final class CallFailed extends CallStatus {
  const CallFailed();
}

// ---------------------------------------------------------------------------
// Call type
// ---------------------------------------------------------------------------

/// Audio or video call — stored as SCREAMING_CASE to match backend DTO.
enum CallType {
  audio('AUDIO'),
  video('VIDEO');

  const CallType(this.backendValue);
  final String backendValue;

  /// Parses backend strings like `"voice"`, `"AUDIO"`, `"video"`, `"VIDEO"`.
  ///
  /// Defaults to [CallType.audio] for unrecognized values.
  static CallType fromBackend(String raw) {
    final upper = raw.toUpperCase();
    if (upper == 'VIDEO') return CallType.video;
    // Backend sends "voice" for audio calls — normalize.
    return CallType.audio;
  }
}

// ---------------------------------------------------------------------------
// Call direction
// ---------------------------------------------------------------------------

enum CallDirection { outgoing, incoming }

// ---------------------------------------------------------------------------
// Call end reason
// ---------------------------------------------------------------------------

enum CallEndReason {
  hangup,
  declined,
  noAnswer,
  busy,
  cancelled,
  failed,
  answeredElsewhere,
  declinedElsewhere,
  timeout,
  permissionDenied,
}

// ---------------------------------------------------------------------------
// Call info — immutable snapshot of a single call
// ---------------------------------------------------------------------------

final class CallInfo {
  const CallInfo({
    required this.callId,
    required this.roomName,
    required this.callType,
    required this.direction,
    required this.remoteUserId,
    required this.remoteUsername,
    required this.remotePhotoUrl,
  });

  final String callId;
  final String roomName;
  final CallType callType;
  final CallDirection direction;
  final String remoteUserId;
  final String remoteUsername;
  final String? remotePhotoUrl;
}

// ---------------------------------------------------------------------------
// Media state (local)
// ---------------------------------------------------------------------------

final class MediaState {
  const MediaState({this.isMuted = false, this.isCameraOn = true});

  final bool isMuted;
  final bool isCameraOn;

  MediaState copyWith({bool? isMuted, bool? isCameraOn}) {
    return MediaState(
      isMuted: isMuted ?? this.isMuted,
      isCameraOn: isCameraOn ?? this.isCameraOn,
    );
  }
}

// ---------------------------------------------------------------------------
// Remote media state
// ---------------------------------------------------------------------------

final class RemoteMediaState {
  const RemoteMediaState({this.isAudioMuted = false, this.isVideoOff = false});

  final bool isAudioMuted;
  final bool isVideoOff;
}

// ---------------------------------------------------------------------------
// REST DTOs
// ---------------------------------------------------------------------------

final class CallRoomResponse {
  const CallRoomResponse({
    required this.roomName,
    required this.roomSid,
    required this.callId,
  });

  final String roomName;
  final String roomSid;
  final String callId;

  factory CallRoomResponse.fromJson(Map<String, Object?> json) {
    return CallRoomResponse(
      roomName: json['roomName'] as String? ?? '',
      roomSid: json['roomSid'] as String? ?? '',
      callId: json['callId'] as String? ?? '',
    );
  }
}

final class IceServerDto {
  const IceServerDto({required this.urls, this.username, this.credential});

  /// Backend may send a single String or a `List<String>`.
  final List<String> urls;
  final String? username;
  final String? credential;

  /// Parses an ICE server entry, normalizing [urls] to always be a List.
  factory IceServerDto.fromJson(Map<String, Object?> json) {
    final rawUrls = json['urls'];
    final List<String> parsedUrls;
    if (rawUrls is String) {
      parsedUrls = [rawUrls];
    } else if (rawUrls is List) {
      parsedUrls = rawUrls.whereType<String>().toList();
    } else {
      parsedUrls = [];
    }

    return IceServerDto(
      urls: parsedUrls,
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// ICE candidate (portable, no platform dependency)
// ---------------------------------------------------------------------------

final class IceCandidateInfo {
  const IceCandidateInfo({
    required this.candidate,
    required this.sdpMid,
    required this.sdpMLineIndex,
  });

  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;
}

// ---------------------------------------------------------------------------
// STOMP incoming call payload
// ---------------------------------------------------------------------------

final class StompIncomingCallPayload {
  const StompIncomingCallPayload({
    required this.type,
    required this.roomName,
    this.callId,
    this.callType,
    this.callerId,
    this.userId,
    this.callerName,
    this.callerUsername,
    this.callerPhoto,
    this.callerPhotoUrl,
    this.targetUserId,
    this.reason,
  });

  final String type;
  final String roomName;
  final String? callId;
  final String? callType;
  final String? callerId;
  final String? userId;
  final String? callerName;
  final String? callerUsername;
  final String? callerPhoto;
  final String? callerPhotoUrl;
  final String? targetUserId;
  final String? reason;

  factory StompIncomingCallPayload.fromJson(Map<String, Object?> json) {
    return StompIncomingCallPayload(
      type: json['type'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      callId: json['callId'] as String?,
      callType: json['callType']?.toString(),
      callerId: json['callerId']?.toString(),
      userId: json['userId']?.toString(),
      callerName: json['callerName'] as String?,
      callerUsername: json['callerUsername'] as String?,
      callerPhoto: json['callerPhoto'] as String?,
      callerPhotoUrl: json['callerPhotoUrl'] as String?,
      targetUserId: json['targetUserId']?.toString(),
      reason: json['reason'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// WebRTC signal message
// ---------------------------------------------------------------------------

final class WebrtcSignalMessage {
  const WebrtcSignalMessage({
    required this.roomName,
    required this.type,
    this.sdp,
    this.candidate,
    this.reason,
    this.audioMuted,
    this.videoOff,
    this.targetUserId,
  });

  final String roomName;

  /// One of: offer, answer, ice, ice-candidate, hangup, busy, media_state, ring_ack
  final String type;
  final String? sdp;
  final IceCandidateInfo? candidate;
  final String? reason;
  final bool? audioMuted;
  final bool? videoOff;
  final int? targetUserId;

  factory WebrtcSignalMessage.fromJson(Map<String, Object?> json) {
    IceCandidateInfo? candidateInfo;
    final rawCandidate = json['candidate'];
    if (rawCandidate is Map<String, Object?>) {
      candidateInfo = IceCandidateInfo(
        candidate: rawCandidate['candidate'] as String? ?? '',
        sdpMid: rawCandidate['sdpMid'] as String?,
        sdpMLineIndex: _parseOptionalInt(rawCandidate['sdpMLineIndex']),
      );
    }

    return WebrtcSignalMessage(
      roomName: json['roomName'] as String? ?? '',
      type: json['type'] as String? ?? '',
      sdp: json['sdp'] as String?,
      candidate: candidateInfo,
      reason: json['reason'] as String?,
      audioMuted: json['audioMuted'] as bool?,
      videoOff: json['videoOff'] as bool?,
      targetUserId: _parseOptionalInt(json['targetUserId']),
    );
  }
}

int? _parseOptionalInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is String) return int.tryParse(raw);
  return null;
}

/// Returns the userId for STOMP payloads.
///
/// The backend accepts targetUserId as either String or int (via toString).
/// UUID strings are passed through directly.
String parseTargetUserId(String userId) => userId;
