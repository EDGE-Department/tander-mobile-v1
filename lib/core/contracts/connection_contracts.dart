/// Connection domain -- raw backend DTOs.
/// NOTE: Backend uses "matches" internally. UI always says "Connection".
library;

import 'package:json_annotation/json_annotation.dart';

part 'connection_contracts.g.dart';

// ---------------------------------------------------------------------------
// Match DTO - matches backend's MatchDto.java
// ---------------------------------------------------------------------------

@JsonSerializable()
class MatchDto {
  const MatchDto({
    required this.id,
    required this.otherUserId,
    required this.status,
    this.otherUsername,
    this.otherDisplayName,
    this.otherProfilePhotoUrl,
    this.otherAge,
    this.otherOnline = false,
    this.matchedAt,
    this.lastMessageAt,
  });

  factory MatchDto.fromJson(Map<String, Object?> json) =>
      _$MatchDtoFromJson(json);

  final String id;
  final String otherUserId;
  final String? otherUsername;
  final String? otherDisplayName;
  final String? otherProfilePhotoUrl;
  final int? otherAge;
  final bool otherOnline;

  /// 'PENDING', 'ACCEPTED', 'DECLINED', 'BLOCKED', or 'UNMATCHED'
  final String status;
  final String? matchedAt;
  final String? lastMessageAt;

  Map<String, Object?> toJson() => _$MatchDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Spring pagination wrapper
// ---------------------------------------------------------------------------

@JsonSerializable(genericArgumentFactories: true)
class SpringPageDto<TItem> {
  const SpringPageDto({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
  });

  factory SpringPageDto.fromJson(
    Map<String, Object?> json,
    TItem Function(Object? json) fromJsonTItem,
  ) => _$SpringPageDtoFromJson(json, fromJsonTItem);

  final List<TItem> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;

  Map<String, Object?> toJson(Object? Function(TItem value) toJsonTItem) =>
      _$SpringPageDtoToJson(this, toJsonTItem);
}

// ---------------------------------------------------------------------------
// Swipe - matches backend's SwipeApiRequest.java and SwipeApiResponse.java
// ---------------------------------------------------------------------------

@JsonSerializable()
class SwipeRequestDto {
  const SwipeRequestDto({required this.targetUserId, required this.direction});

  factory SwipeRequestDto.fromJson(Map<String, Object?> json) =>
      _$SwipeRequestDtoFromJson(json);

  final String targetUserId;

  /// 'LEFT' or 'RIGHT'
  final String direction;

  Map<String, Object?> toJson() => _$SwipeRequestDtoToJson(this);
}

@JsonSerializable()
class SwipeResponseDto {
  const SwipeResponseDto({
    required this.matched,
    required this.swipesRemaining,
    this.match,
  });

  factory SwipeResponseDto.fromJson(Map<String, Object?> json) =>
      _$SwipeResponseDtoFromJson(json);

  final bool matched;
  final MatchDto? match;
  final int swipesRemaining;

  Map<String, Object?> toJson() => _$SwipeResponseDtoToJson(this);
}
