// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calls_v2_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartCallRequestDto _$StartCallRequestDtoFromJson(Map<String, dynamic> json) =>
    StartCallRequestDto(
      calleeUserId: json['calleeUserId'] as String,
      callType: json['callType'] as String,
      deviceId: json['deviceId'] as String,
      idempotencyKey: json['idempotencyKey'] as String,
    );

Map<String, dynamic> _$StartCallRequestDtoToJson(
  StartCallRequestDto instance,
) => <String, dynamic>{
  'calleeUserId': instance.calleeUserId,
  'callType': instance.callType,
  'deviceId': instance.deviceId,
  'idempotencyKey': instance.idempotencyKey,
};

StartCallResponseDto _$StartCallResponseDtoFromJson(
  Map<String, dynamic> json,
) => StartCallResponseDto(
  callId: json['callId'] as String,
  state: json['state'] as String,
  stateVersion: (json['stateVersion'] as num).toInt(),
  roomName: json['roomName'] as String,
  twilioRoomSid: json['twilioRoomSid'] as String,
  twilioToken: json['twilioToken'] as String,
  expiresAt: json['expiresAt'] as String,
);

Map<String, dynamic> _$StartCallResponseDtoToJson(
  StartCallResponseDto instance,
) => <String, dynamic>{
  'callId': instance.callId,
  'state': instance.state,
  'stateVersion': instance.stateVersion,
  'roomName': instance.roomName,
  'twilioRoomSid': instance.twilioRoomSid,
  'twilioToken': instance.twilioToken,
  'expiresAt': instance.expiresAt,
};

DeviceRequestDto _$DeviceRequestDtoFromJson(Map<String, dynamic> json) =>
    DeviceRequestDto(
      deviceId: json['deviceId'] as String,
      idempotencyKey: json['idempotencyKey'] as String,
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$DeviceRequestDtoToJson(DeviceRequestDto instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'idempotencyKey': instance.idempotencyKey,
      'reason': instance.reason,
    };

AcceptResponseDto _$AcceptResponseDtoFromJson(Map<String, dynamic> json) =>
    AcceptResponseDto(
      callId: json['callId'] as String,
      state: json['state'] as String,
      stateVersion: (json['stateVersion'] as num).toInt(),
      accepted: json['accepted'] as bool,
      outcome: json['outcome'] as String,
      roomName: json['roomName'] as String?,
      twilioRoomSid: json['twilioRoomSid'] as String?,
      twilioToken: json['twilioToken'] as String?,
      answeredByDeviceId: json['answeredByDeviceId'] as String?,
    );

Map<String, dynamic> _$AcceptResponseDtoToJson(AcceptResponseDto instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'state': instance.state,
      'stateVersion': instance.stateVersion,
      'accepted': instance.accepted,
      'outcome': instance.outcome,
      'roomName': instance.roomName,
      'twilioRoomSid': instance.twilioRoomSid,
      'twilioToken': instance.twilioToken,
      'answeredByDeviceId': instance.answeredByDeviceId,
    };

TerminalResponseDto _$TerminalResponseDtoFromJson(Map<String, dynamic> json) =>
    TerminalResponseDto(
      callId: json['callId'] as String,
      state: json['state'] as String,
      stateVersion: (json['stateVersion'] as num).toInt(),
      endReason: json['endReason'] as String?,
    );

Map<String, dynamic> _$TerminalResponseDtoToJson(
  TerminalResponseDto instance,
) => <String, dynamic>{
  'callId': instance.callId,
  'state': instance.state,
  'stateVersion': instance.stateVersion,
  'endReason': instance.endReason,
};

HandoffRequestDto _$HandoffRequestDtoFromJson(Map<String, dynamic> json) =>
    HandoffRequestDto(
      fromDeviceId: json['fromDeviceId'] as String,
      toDeviceId: json['toDeviceId'] as String,
      role: json['role'] as String,
      idempotencyKey: json['idempotencyKey'] as String,
    );

Map<String, dynamic> _$HandoffRequestDtoToJson(HandoffRequestDto instance) =>
    <String, dynamic>{
      'fromDeviceId': instance.fromDeviceId,
      'toDeviceId': instance.toDeviceId,
      'role': instance.role,
      'idempotencyKey': instance.idempotencyKey,
    };

HandoffResponseDto _$HandoffResponseDtoFromJson(Map<String, dynamic> json) =>
    HandoffResponseDto(
      callId: json['callId'] as String,
      state: json['state'] as String,
      stateVersion: (json['stateVersion'] as num).toInt(),
      handoffCompleted: json['handoffCompleted'] as bool,
      twilioToken: json['twilioToken'] as String?,
      roomName: json['roomName'] as String?,
      twilioRoomSid: json['twilioRoomSid'] as String?,
    );

Map<String, dynamic> _$HandoffResponseDtoToJson(HandoffResponseDto instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'state': instance.state,
      'stateVersion': instance.stateVersion,
      'handoffCompleted': instance.handoffCompleted,
      'twilioToken': instance.twilioToken,
      'roomName': instance.roomName,
      'twilioRoomSid': instance.twilioRoomSid,
    };

ActiveCallEnvelopeDto _$ActiveCallEnvelopeDtoFromJson(
  Map<String, dynamic> json,
) => ActiveCallEnvelopeDto(
  callId: json['callId'] as String,
  state: json['state'] as String,
  stateVersion: (json['stateVersion'] as num).toInt(),
  role: json['role'] as String,
  peerUserId: json['peerUserId'] as String,
  callType: json['callType'] as String,
  roomName: json['roomName'] as String,
  twilioRoomSid: json['twilioRoomSid'] as String,
  startedAt: json['startedAt'] as String,
  canRejoin: json['canRejoin'] as bool,
  reason: json['reason'] as String?,
  activeDeviceId: json['activeDeviceId'] as String?,
  rejoinToken: json['rejoinToken'] as String?,
  rejoinTokenExpiresAt: json['rejoinTokenExpiresAt'] as String?,
);

Map<String, dynamic> _$ActiveCallEnvelopeDtoToJson(
  ActiveCallEnvelopeDto instance,
) => <String, dynamic>{
  'callId': instance.callId,
  'state': instance.state,
  'stateVersion': instance.stateVersion,
  'role': instance.role,
  'peerUserId': instance.peerUserId,
  'callType': instance.callType,
  'roomName': instance.roomName,
  'twilioRoomSid': instance.twilioRoomSid,
  'startedAt': instance.startedAt,
  'canRejoin': instance.canRejoin,
  'reason': instance.reason,
  'activeDeviceId': instance.activeDeviceId,
  'rejoinToken': instance.rejoinToken,
  'rejoinTokenExpiresAt': instance.rejoinTokenExpiresAt,
};

ActiveCallResponseDto _$ActiveCallResponseDtoFromJson(
  Map<String, dynamic> json,
) => ActiveCallResponseDto(
  active: json['active'] == null
      ? null
      : ActiveCallEnvelopeDto.fromJson(json['active'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ActiveCallResponseDtoToJson(
  ActiveCallResponseDto instance,
) => <String, dynamic>{'active': instance.active};

RejoinTokenResponseDto _$RejoinTokenResponseDtoFromJson(
  Map<String, dynamic> json,
) => RejoinTokenResponseDto(
  callId: json['callId'] as String,
  roomName: json['roomName'] as String,
  twilioRoomSid: json['twilioRoomSid'] as String,
  twilioToken: json['twilioToken'] as String,
  expiresAt: json['expiresAt'] as String,
);

Map<String, dynamic> _$RejoinTokenResponseDtoToJson(
  RejoinTokenResponseDto instance,
) => <String, dynamic>{
  'callId': instance.callId,
  'roomName': instance.roomName,
  'twilioRoomSid': instance.twilioRoomSid,
  'twilioToken': instance.twilioToken,
  'expiresAt': instance.expiresAt,
};

ActionTokenRequestDto _$ActionTokenRequestDtoFromJson(
  Map<String, dynamic> json,
) => ActionTokenRequestDto(
  callActionToken: json['callActionToken'] as String,
  deviceId: json['deviceId'] as String,
  idempotencyKey: json['idempotencyKey'] as String,
);

Map<String, dynamic> _$ActionTokenRequestDtoToJson(
  ActionTokenRequestDto instance,
) => <String, dynamic>{
  'callActionToken': instance.callActionToken,
  'deviceId': instance.deviceId,
  'idempotencyKey': instance.idempotencyKey,
};

NegotiateResponseDto _$NegotiateResponseDtoFromJson(
  Map<String, dynamic> json,
) => NegotiateResponseDto(
  url: json['url'] as String,
  accessToken: json['accessToken'] as String,
  expiresAt: json['expiresAt'] as String,
  hubName: json['hubName'] as String,
  userId: json['userId'] as String,
  deviceId: json['deviceId'] as String,
  sessionId: json['sessionId'] as String,
  envelopeVersion: (json['envelopeVersion'] as num).toInt(),
);

Map<String, dynamic> _$NegotiateResponseDtoToJson(
  NegotiateResponseDto instance,
) => <String, dynamic>{
  'url': instance.url,
  'accessToken': instance.accessToken,
  'expiresAt': instance.expiresAt,
  'hubName': instance.hubName,
  'userId': instance.userId,
  'deviceId': instance.deviceId,
  'sessionId': instance.sessionId,
  'envelopeVersion': instance.envelopeVersion,
};
