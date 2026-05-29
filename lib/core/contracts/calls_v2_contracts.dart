/// Calls v2 domain — Phase 5 native Twilio Programmable Video + Web PubSub.
///
/// Mirrors backend record DTOs in `tander-backend/src/main/java/com/tander/
/// calls/v2/api/CallsV2Controller.java` and `CallsV2ActionTokenController.java`.
///
/// All UUIDs are wire-encoded as strings. All Instants are ISO-8601 strings.
library;

import 'package:json_annotation/json_annotation.dart';

part 'calls_v2_contracts.g.dart';

// ---------------------------------------------------------------------------
// Start call
// ---------------------------------------------------------------------------

@JsonSerializable()
class StartCallRequestDto {
  const StartCallRequestDto({
    required this.calleeUserId,
    required this.callType,
    required this.deviceId,
    required this.idempotencyKey,
  });

  factory StartCallRequestDto.fromJson(Map<String, Object?> json) =>
      _$StartCallRequestDtoFromJson(json);

  /// UUID string.
  final String calleeUserId;

  /// 'AUDIO' or 'VIDEO'.
  final String callType;

  /// Stable per-install device UUID (matches X-Tander-Device-Id header).
  final String deviceId;

  /// Client-generated UUID v4 for idempotency on POST /api/v2/calls.
  final String idempotencyKey;

  Map<String, Object?> toJson() => _$StartCallRequestDtoToJson(this);
}

@JsonSerializable()
class StartCallResponseDto {
  const StartCallResponseDto({
    required this.callId,
    required this.state,
    required this.stateVersion,
    required this.roomName,
    required this.twilioRoomSid,
    required this.twilioToken,
    required this.expiresAt,
  });

  factory StartCallResponseDto.fromJson(Map<String, Object?> json) =>
      _$StartCallResponseDtoFromJson(json);

  final String callId;
  final String state;
  final int stateVersion;
  final String roomName;
  final String twilioRoomSid;
  final String twilioToken;

  /// ISO-8601.
  final String expiresAt;

  Map<String, Object?> toJson() => _$StartCallResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Per-device action requests (accept / decline / cancel / end / dismiss)
// ---------------------------------------------------------------------------

@JsonSerializable()
class DeviceRequestDto {
  const DeviceRequestDto({
    required this.deviceId,
    required this.idempotencyKey,
    this.reason,
  });

  factory DeviceRequestDto.fromJson(Map<String, Object?> json) =>
      _$DeviceRequestDtoFromJson(json);

  final String deviceId;
  final String idempotencyKey;
  final String? reason;

  Map<String, Object?> toJson() => _$DeviceRequestDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Accept response (also returned by accept-action)
// ---------------------------------------------------------------------------

@JsonSerializable()
class AcceptResponseDto {
  const AcceptResponseDto({
    required this.callId,
    required this.state,
    required this.stateVersion,
    required this.accepted,
    required this.outcome,
    this.roomName,
    this.twilioRoomSid,
    this.twilioToken,
    this.answeredByDeviceId,
  });

  factory AcceptResponseDto.fromJson(Map<String, Object?> json) =>
      _$AcceptResponseDtoFromJson(json);

  final String callId;
  final String state;
  final int stateVersion;
  final bool accepted;
  final String outcome;
  final String? roomName;
  final String? twilioRoomSid;
  final String? twilioToken;
  final String? answeredByDeviceId;

  Map<String, Object?> toJson() => _$AcceptResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Terminal response (decline / cancel / end)
// ---------------------------------------------------------------------------

@JsonSerializable()
class TerminalResponseDto {
  const TerminalResponseDto({
    required this.callId,
    required this.state,
    required this.stateVersion,
    this.endReason,
  });

  factory TerminalResponseDto.fromJson(Map<String, Object?> json) =>
      _$TerminalResponseDtoFromJson(json);

  final String callId;
  final String state;
  final int stateVersion;
  final String? endReason;

  Map<String, Object?> toJson() => _$TerminalResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Handoff
// ---------------------------------------------------------------------------

@JsonSerializable()
class HandoffRequestDto {
  const HandoffRequestDto({
    required this.fromDeviceId,
    required this.toDeviceId,
    required this.role,
    required this.idempotencyKey,
  });

  factory HandoffRequestDto.fromJson(Map<String, Object?> json) =>
      _$HandoffRequestDtoFromJson(json);

  final String fromDeviceId;
  final String toDeviceId;

  /// 'caller' or 'callee'.
  final String role;
  final String idempotencyKey;

  Map<String, Object?> toJson() => _$HandoffRequestDtoToJson(this);
}

@JsonSerializable()
class HandoffResponseDto {
  const HandoffResponseDto({
    required this.callId,
    required this.state,
    required this.stateVersion,
    required this.handoffCompleted,
    this.twilioToken,
    this.roomName,
    this.twilioRoomSid,
  });

  factory HandoffResponseDto.fromJson(Map<String, Object?> json) =>
      _$HandoffResponseDtoFromJson(json);

  final String callId;
  final String state;
  final int stateVersion;
  final bool handoffCompleted;
  final String? twilioToken;
  final String? roomName;
  final String? twilioRoomSid;

  Map<String, Object?> toJson() => _$HandoffResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Active call (preflight + recovery)
// ---------------------------------------------------------------------------

@JsonSerializable()
class ActiveCallEnvelopeDto {
  const ActiveCallEnvelopeDto({
    required this.callId,
    required this.state,
    required this.stateVersion,
    required this.role,
    required this.peerUserId,
    required this.callType,
    required this.roomName,
    required this.twilioRoomSid,
    required this.startedAt,
    required this.canRejoin,
    this.reason,
    this.activeDeviceId,
    this.rejoinToken,
    this.rejoinTokenExpiresAt,
  });

  factory ActiveCallEnvelopeDto.fromJson(Map<String, Object?> json) =>
      _$ActiveCallEnvelopeDtoFromJson(json);

  final String callId;
  final String state;
  final int stateVersion;

  /// 'caller' or 'callee'.
  final String role;
  final String peerUserId;
  final String callType;
  final String roomName;
  final String twilioRoomSid;
  final String startedAt;
  final bool canRejoin;
  final String? reason;
  final String? activeDeviceId;
  final String? rejoinToken;
  final String? rejoinTokenExpiresAt;

  Map<String, Object?> toJson() => _$ActiveCallEnvelopeDtoToJson(this);
}

@JsonSerializable()
class ActiveCallResponseDto {
  const ActiveCallResponseDto({this.active});

  factory ActiveCallResponseDto.fromJson(Map<String, Object?> json) =>
      _$ActiveCallResponseDtoFromJson(json);

  final ActiveCallEnvelopeDto? active;

  Map<String, Object?> toJson() => _$ActiveCallResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Rejoin token refresh
// ---------------------------------------------------------------------------

@JsonSerializable()
class RejoinTokenResponseDto {
  const RejoinTokenResponseDto({
    required this.callId,
    required this.roomName,
    required this.twilioRoomSid,
    required this.twilioToken,
    required this.expiresAt,
  });

  factory RejoinTokenResponseDto.fromJson(Map<String, Object?> json) =>
      _$RejoinTokenResponseDtoFromJson(json);

  final String callId;
  final String roomName;
  final String twilioRoomSid;
  final String twilioToken;
  final String expiresAt;

  Map<String, Object?> toJson() => _$RejoinTokenResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Killed-app action-token requests (no JWT — opaque callActionToken)
// ---------------------------------------------------------------------------

@JsonSerializable()
class ActionTokenRequestDto {
  const ActionTokenRequestDto({
    required this.callActionToken,
    required this.deviceId,
    required this.idempotencyKey,
  });

  factory ActionTokenRequestDto.fromJson(Map<String, Object?> json) =>
      _$ActionTokenRequestDtoFromJson(json);

  /// Opaque 43-char Base64URL — never decode or inspect.
  final String callActionToken;
  final String deviceId;
  final String idempotencyKey;

  Map<String, Object?> toJson() => _$ActionTokenRequestDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Realtime negotiate (Azure Web PubSub access token mint)
// ---------------------------------------------------------------------------

@JsonSerializable()
class NegotiateResponseDto {
  const NegotiateResponseDto({
    required this.url,
    required this.accessToken,
    required this.expiresAt,
    required this.hubName,
    required this.userId,
    required this.deviceId,
    required this.sessionId,
    required this.envelopeVersion,
  });

  factory NegotiateResponseDto.fromJson(Map<String, Object?> json) =>
      _$NegotiateResponseDtoFromJson(json);

  /// Full WS URL with `?access_token=...` query param appended by backend.
  final String url;
  final String accessToken;
  final String expiresAt;
  final String hubName;
  final String userId;
  final String deviceId;
  final String sessionId;
  final int envelopeVersion;

  Map<String, Object?> toJson() => _$NegotiateResponseDtoToJson(this);
}
