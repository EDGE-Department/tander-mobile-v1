// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchDto _$MatchDtoFromJson(Map<String, dynamic> json) => MatchDto(
  id: json['id'] as String,
  otherUserId: json['otherUserId'] as String,
  status: json['status'] as String,
  otherUsername: json['otherUsername'] as String?,
  otherDisplayName: json['otherDisplayName'] as String?,
  otherProfilePhotoUrl: json['otherProfilePhotoUrl'] as String?,
  otherAge: (json['otherAge'] as num?)?.toInt(),
  otherOnline: json['otherOnline'] as bool? ?? false,
  matchedAt: json['matchedAt'] as String?,
  lastMessageAt: json['lastMessageAt'] as String?,
);

Map<String, dynamic> _$MatchDtoToJson(MatchDto instance) => <String, dynamic>{
  'id': instance.id,
  'otherUserId': instance.otherUserId,
  'otherUsername': instance.otherUsername,
  'otherDisplayName': instance.otherDisplayName,
  'otherProfilePhotoUrl': instance.otherProfilePhotoUrl,
  'otherAge': instance.otherAge,
  'otherOnline': instance.otherOnline,
  'status': instance.status,
  'matchedAt': instance.matchedAt,
  'lastMessageAt': instance.lastMessageAt,
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
      targetUserId: json['targetUserId'] as String,
      direction: json['direction'] as String,
    );

Map<String, dynamic> _$SwipeRequestDtoToJson(SwipeRequestDto instance) =>
    <String, dynamic>{
      'targetUserId': instance.targetUserId,
      'direction': instance.direction,
    };

SwipeResponseDto _$SwipeResponseDtoFromJson(Map<String, dynamic> json) =>
    SwipeResponseDto(
      matched: json['matched'] as bool,
      swipesRemaining: (json['swipesRemaining'] as num).toInt(),
      match: json['match'] == null
          ? null
          : MatchDto.fromJson(json['match'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwipeResponseDtoToJson(SwipeResponseDto instance) =>
    <String, dynamic>{
      'matched': instance.matched,
      'match': instance.match,
      'swipesRemaining': instance.swipesRemaining,
    };
