/// Calls domain -- raw backend DTOs.
/// Twilio Video handles media. STOMP handles call lifecycle events.
library;

import 'package:json_annotation/json_annotation.dart';

part 'calls_contracts.g.dart';

// ---------------------------------------------------------------------------
// Create call room
// ---------------------------------------------------------------------------

@JsonSerializable()
class CreateCallRoomRequestDto {
  const CreateCallRoomRequestDto({
    required this.targetUserId,
    required this.callType,
  });

  factory CreateCallRoomRequestDto.fromJson(Map<String, Object?> json) =>
      _$CreateCallRoomRequestDtoFromJson(json);

  final String targetUserId;

  /// 'VIDEO' or 'AUDIO'
  final String callType;

  Map<String, Object?> toJson() => _$CreateCallRoomRequestDtoToJson(this);
}

@JsonSerializable()
class CallRoomResponseDto {
  const CallRoomResponseDto({
    required this.roomName,
    required this.roomSid,
    required this.callId,
  });

  factory CallRoomResponseDto.fromJson(Map<String, Object?> json) =>
      _$CallRoomResponseDtoFromJson(json);

  final String roomName;
  final String roomSid;
  final String callId;

  Map<String, Object?> toJson() => _$CallRoomResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Call token
// ---------------------------------------------------------------------------

@JsonSerializable()
class CallTokenRequestDto {
  const CallTokenRequestDto({required this.roomName});

  factory CallTokenRequestDto.fromJson(Map<String, Object?> json) =>
      _$CallTokenRequestDtoFromJson(json);

  final String roomName;

  Map<String, Object?> toJson() => _$CallTokenRequestDtoToJson(this);
}

@JsonSerializable()
class CallTokenResponseDto {
  const CallTokenResponseDto({required this.token, required this.identity});

  factory CallTokenResponseDto.fromJson(Map<String, Object?> json) =>
      _$CallTokenResponseDtoFromJson(json);

  final String token;
  final String identity;

  Map<String, Object?> toJson() => _$CallTokenResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Call history
// ---------------------------------------------------------------------------

@JsonSerializable()
class CallHistoryItemDto {
  const CallHistoryItemDto({
    required this.callId,
    required this.roomName,
    required this.callType,
    required this.participantUserId,
    required this.participantUsername,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.participantPhotoUrl,
    this.durationSeconds,
    this.endedAt,
  });

  factory CallHistoryItemDto.fromJson(Map<String, Object?> json) =>
      _$CallHistoryItemDtoFromJson(json);

  final String callId;
  final String roomName;

  /// 'VIDEO' or 'AUDIO'
  final String callType;
  final String participantUserId;
  final String participantUsername;
  final String? participantPhotoUrl;

  /// 'OUTGOING' or 'INCOMING'
  final String direction;

  /// 'COMPLETED', 'MISSED', 'DECLINED', or 'CANCELLED'
  final String status;
  final int? durationSeconds;
  final String startedAt;
  final String? endedAt;

  Map<String, Object?> toJson() => _$CallHistoryItemDtoToJson(this);
}

// ---------------------------------------------------------------------------
// ICE servers
// ---------------------------------------------------------------------------

@JsonSerializable()
class IceServerDto {
  const IceServerDto({required this.urls, this.username, this.credential});

  factory IceServerDto.fromJson(Map<String, Object?> json) =>
      _$IceServerDtoFromJson(json);

  /// Can be a single String or a `List<String>` from the backend.
  /// Stored as Object? because json_serializable cannot union String | List.
  /// The mapper layer normalises this into `List<String>`.
  @JsonKey(fromJson: _iceUrlsFromJson, toJson: _iceUrlsToJson)
  final Object urls;

  final String? username;
  final String? credential;

  Map<String, Object?> toJson() => _$IceServerDtoToJson(this);
}

Object _iceUrlsFromJson(Object? json) {
  if (json is List) {
    return json.cast<String>();
  }
  return json ?? '';
}

Object _iceUrlsToJson(Object urls) => urls;

@JsonSerializable()
class IceServersResponseDto {
  const IceServersResponseDto({required this.iceServers});

  factory IceServersResponseDto.fromJson(Map<String, Object?> json) =>
      _$IceServersResponseDtoFromJson(json);

  final List<IceServerDto> iceServers;

  Map<String, Object?> toJson() => _$IceServersResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// STOMP call lifecycle event payloads
// ---------------------------------------------------------------------------

@JsonSerializable()
class StompCallEventPayload {
  const StompCallEventPayload({
    required this.type,
    required this.callId,
    required this.roomName,
    required this.callType,
    required this.callerId,
    required this.callerUsername,
    required this.targetUserId,
    this.callerPhotoUrl,
  });

  factory StompCallEventPayload.fromJson(Map<String, Object?> json) =>
      _$StompCallEventPayloadFromJson(json);

  /// One of: 'incoming_call', 'call_answered', 'call_answered_elsewhere',
  /// 'call_declined', 'call_declined_elsewhere', 'call_ended',
  /// 'call_cancelled'.
  final String type;
  final String callId;
  final String roomName;

  /// 'VIDEO' or 'AUDIO'
  final String callType;
  final String callerId;
  final String callerUsername;
  final String? callerPhotoUrl;
  final String targetUserId;

  Map<String, Object?> toJson() => _$StompCallEventPayloadToJson(this);
}
