// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calls_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCallRoomRequestDto _$CreateCallRoomRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateCallRoomRequestDto(
  targetUserId: json['targetUserId'] as String,
  callType: json['callType'] as String,
);

Map<String, dynamic> _$CreateCallRoomRequestDtoToJson(
  CreateCallRoomRequestDto instance,
) => <String, dynamic>{
  'targetUserId': instance.targetUserId,
  'callType': instance.callType,
};

CallRoomResponseDto _$CallRoomResponseDtoFromJson(Map<String, dynamic> json) =>
    CallRoomResponseDto(
      roomName: json['roomName'] as String,
      roomSid: json['roomSid'] as String,
      callId: json['callId'] as String,
    );

Map<String, dynamic> _$CallRoomResponseDtoToJson(
  CallRoomResponseDto instance,
) => <String, dynamic>{
  'roomName': instance.roomName,
  'roomSid': instance.roomSid,
  'callId': instance.callId,
};

CallTokenRequestDto _$CallTokenRequestDtoFromJson(Map<String, dynamic> json) =>
    CallTokenRequestDto(roomName: json['roomName'] as String);

Map<String, dynamic> _$CallTokenRequestDtoToJson(
  CallTokenRequestDto instance,
) => <String, dynamic>{'roomName': instance.roomName};

CallTokenResponseDto _$CallTokenResponseDtoFromJson(
  Map<String, dynamic> json,
) => CallTokenResponseDto(
  token: json['token'] as String,
  identity: json['identity'] as String,
);

Map<String, dynamic> _$CallTokenResponseDtoToJson(
  CallTokenResponseDto instance,
) => <String, dynamic>{'token': instance.token, 'identity': instance.identity};

CallHistoryItemDto _$CallHistoryItemDtoFromJson(Map<String, dynamic> json) =>
    CallHistoryItemDto(
      callId: json['callId'] as String,
      roomName: json['roomName'] as String,
      callType: json['callType'] as String,
      participantUserId: json['participantUserId'] as String,
      participantUsername: json['participantUsername'] as String,
      direction: json['direction'] as String,
      status: json['status'] as String,
      startedAt: json['startedAt'] as String,
      participantPhotoUrl: json['participantPhotoUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      endedAt: json['endedAt'] as String?,
    );

Map<String, dynamic> _$CallHistoryItemDtoToJson(CallHistoryItemDto instance) =>
    <String, dynamic>{
      'callId': instance.callId,
      'roomName': instance.roomName,
      'callType': instance.callType,
      'participantUserId': instance.participantUserId,
      'participantUsername': instance.participantUsername,
      'participantPhotoUrl': instance.participantPhotoUrl,
      'direction': instance.direction,
      'status': instance.status,
      'durationSeconds': instance.durationSeconds,
      'startedAt': instance.startedAt,
      'endedAt': instance.endedAt,
    };

IceServerDto _$IceServerDtoFromJson(Map<String, dynamic> json) => IceServerDto(
  urls: _iceUrlsFromJson(json['urls']),
  username: json['username'] as String?,
  credential: json['credential'] as String?,
);

Map<String, dynamic> _$IceServerDtoToJson(IceServerDto instance) =>
    <String, dynamic>{
      'urls': _iceUrlsToJson(instance.urls),
      'username': instance.username,
      'credential': instance.credential,
    };

IceServersResponseDto _$IceServersResponseDtoFromJson(
  Map<String, dynamic> json,
) => IceServersResponseDto(
  iceServers: (json['iceServers'] as List<dynamic>)
      .map((e) => IceServerDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IceServersResponseDtoToJson(
  IceServersResponseDto instance,
) => <String, dynamic>{'iceServers': instance.iceServers};

StompCallEventPayload _$StompCallEventPayloadFromJson(
  Map<String, dynamic> json,
) => StompCallEventPayload(
  type: json['type'] as String,
  callId: json['callId'] as String,
  roomName: json['roomName'] as String,
  callType: json['callType'] as String,
  callerId: json['callerId'] as String,
  callerUsername: json['callerUsername'] as String,
  targetUserId: json['targetUserId'] as String,
  callerPhotoUrl: json['callerPhotoUrl'] as String?,
);

Map<String, dynamic> _$StompCallEventPayloadToJson(
  StompCallEventPayload instance,
) => <String, dynamic>{
  'type': instance.type,
  'callId': instance.callId,
  'roomName': instance.roomName,
  'callType': instance.callType,
  'callerId': instance.callerId,
  'callerUsername': instance.callerUsername,
  'callerPhotoUrl': instance.callerPhotoUrl,
  'targetUserId': instance.targetUserId,
};
