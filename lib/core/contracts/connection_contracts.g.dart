// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchDto _$MatchDtoFromJson(Map<String, dynamic> json) => MatchDto(
  id: (json['id'] as num).toInt(),
  matchedUserId: (json['matchedUserId'] as num).toInt(),
  matchedUsername: json['matchedUsername'] as String,
  matchedUserDisplayName: json['matchedUserDisplayName'] as String,
  status: json['status'] as String,
  matchedAt: json['matchedAt'] as String,
  presenceStatus: json['presenceStatus'] as String,
  online: json['online'] as bool,
  initiator: json['initiator'] as bool,
  matchedUserProfilePhotoUrl: json['matchedUserProfilePhotoUrl'] as String?,
  matchedUserAge: (json['matchedUserAge'] as num?)?.toInt(),
  matchedUserLocation: json['matchedUserLocation'] as String?,
  matchedUserBio: json['matchedUserBio'] as String?,
  respondedAt: json['respondedAt'] as String?,
  conversationId: (json['conversationId'] as num?)?.toInt(),
  lastSeenTimestamp: (json['lastSeenTimestamp'] as num?)?.toInt(),
  lastActiveTimestamp: (json['lastActiveTimestamp'] as num?)?.toInt(),
);

Map<String, dynamic> _$MatchDtoToJson(MatchDto instance) => <String, dynamic>{
  'id': instance.id,
  'matchedUserId': instance.matchedUserId,
  'matchedUsername': instance.matchedUsername,
  'matchedUserDisplayName': instance.matchedUserDisplayName,
  'matchedUserProfilePhotoUrl': instance.matchedUserProfilePhotoUrl,
  'matchedUserAge': instance.matchedUserAge,
  'matchedUserLocation': instance.matchedUserLocation,
  'matchedUserBio': instance.matchedUserBio,
  'status': instance.status,
  'matchedAt': instance.matchedAt,
  'respondedAt': instance.respondedAt,
  'conversationId': instance.conversationId,
  'presenceStatus': instance.presenceStatus,
  'lastSeenTimestamp': instance.lastSeenTimestamp,
  'lastActiveTimestamp': instance.lastActiveTimestamp,
  'online': instance.online,
  'initiator': instance.initiator,
};

SpringPageDto<TItem> _$SpringPageDtoFromJson<TItem>(
  Map<String, dynamic> json,
  TItem Function(Object? json) fromJsonTItem,
) => SpringPageDto<TItem>(
  content: (json['content'] as List<dynamic>).map(fromJsonTItem).toList(),
  totalElements: (json['totalElements'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
  number: (json['number'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  first: json['first'] as bool,
  last: json['last'] as bool,
);

Map<String, dynamic> _$SpringPageDtoToJson<TItem>(
  SpringPageDto<TItem> instance,
  Object? Function(TItem value) toJsonTItem,
) => <String, dynamic>{
  'content': instance.content.map(toJsonTItem).toList(),
  'totalElements': instance.totalElements,
  'totalPages': instance.totalPages,
  'number': instance.number,
  'size': instance.size,
  'first': instance.first,
  'last': instance.last,
};

SwipeRequestDto _$SwipeRequestDtoFromJson(Map<String, dynamic> json) =>
    SwipeRequestDto(
      targetUserId: (json['targetUserId'] as num).toInt(),
      direction: json['direction'] as String,
    );

Map<String, dynamic> _$SwipeRequestDtoToJson(SwipeRequestDto instance) =>
    <String, dynamic>{
      'targetUserId': instance.targetUserId,
      'direction': instance.direction,
    };

SwipeResponseDto _$SwipeResponseDtoFromJson(Map<String, dynamic> json) =>
    SwipeResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      match: json['match'] as bool,
      requestSent: json['requestSent'] as bool,
      swipesRemaining: (json['swipesRemaining'] as num).toInt(),
      matchId: (json['matchId'] as num?)?.toInt(),
      matchedUserId: (json['matchedUserId'] as num?)?.toInt(),
      matchedUsername: json['matchedUsername'] as String?,
      matchedUserDisplayName: json['matchedUserDisplayName'] as String?,
      matchedUserProfilePhotoUrl: json['matchedUserProfilePhotoUrl'] as String?,
      matchedAt: json['matchedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );

Map<String, dynamic> _$SwipeResponseDtoToJson(SwipeResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'match': instance.match,
      'requestSent': instance.requestSent,
      'matchId': instance.matchId,
      'matchedUserId': instance.matchedUserId,
      'matchedUsername': instance.matchedUsername,
      'matchedUserDisplayName': instance.matchedUserDisplayName,
      'matchedUserProfilePhotoUrl': instance.matchedUserProfilePhotoUrl,
      'matchedAt': instance.matchedAt,
      'expiresAt': instance.expiresAt,
      'swipesRemaining': instance.swipesRemaining,
    };
