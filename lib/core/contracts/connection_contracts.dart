/// Connection domain -- raw backend DTOs.
/// NOTE: Backend uses "matches" internally. UI always says "Connection".
library;

import 'package:json_annotation/json_annotation.dart';

part 'connection_contracts.g.dart';

// ---------------------------------------------------------------------------
// Match DTO
// ---------------------------------------------------------------------------

@JsonSerializable()
class MatchDto {
  const MatchDto({
    required this.id,
    required this.matchedUserId,
    required this.matchedUsername,
    required this.matchedUserDisplayName,
    required this.status,
    required this.matchedAt,
    required this.presenceStatus,
    required this.online,
    required this.initiator,
    this.matchedUserProfilePhotoUrl,
    this.matchedUserAge,
    this.matchedUserLocation,
    this.matchedUserBio,
    this.respondedAt,
    this.conversationId,
    this.lastSeenTimestamp,
    this.lastActiveTimestamp,
  });

  factory MatchDto.fromJson(Map<String, Object?> json) =>
      _$MatchDtoFromJson(json);

  final int id;
  final int matchedUserId;
  final String matchedUsername;
  final String matchedUserDisplayName;
  final String? matchedUserProfilePhotoUrl;
  final int? matchedUserAge;
  final String? matchedUserLocation;
  final String? matchedUserBio;

  /// 'PENDING', 'ACCEPTED', 'DECLINED', or 'UNMATCHED'
  final String status;
  final String matchedAt;
  final String? respondedAt;
  final int? conversationId;

  /// 'online', 'recently_active', or 'offline'
  final String presenceStatus;
  final int? lastSeenTimestamp;
  final int? lastActiveTimestamp;
  final bool online;
  final bool initiator;

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
  ) =>
      _$SpringPageDtoFromJson(json, fromJsonTItem);

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
// Swipe
// ---------------------------------------------------------------------------

@JsonSerializable()
class SwipeRequestDto {
  const SwipeRequestDto({
    required this.targetUserId,
    required this.direction,
  });

  factory SwipeRequestDto.fromJson(Map<String, Object?> json) =>
      _$SwipeRequestDtoFromJson(json);

  final int targetUserId;

  /// 'LEFT' or 'RIGHT'
  final String direction;

  Map<String, Object?> toJson() => _$SwipeRequestDtoToJson(this);
}

@JsonSerializable()
class SwipeResponseDto {
  const SwipeResponseDto({
    required this.success,
    required this.message,
    required this.match,
    required this.requestSent,
    required this.swipesRemaining,
    this.matchId,
    this.matchedUserId,
    this.matchedUsername,
    this.matchedUserDisplayName,
    this.matchedUserProfilePhotoUrl,
    this.matchedAt,
    this.expiresAt,
  });

  factory SwipeResponseDto.fromJson(Map<String, Object?> json) =>
      _$SwipeResponseDtoFromJson(json);

  final bool success;
  final String message;
  final bool match;
  final bool requestSent;
  final int? matchId;
  final int? matchedUserId;
  final String? matchedUsername;
  final String? matchedUserDisplayName;
  final String? matchedUserProfilePhotoUrl;
  final String? matchedAt;
  final String? expiresAt;
  final int swipesRemaining;

  Map<String, Object?> toJson() => _$SwipeResponseDtoToJson(this);
}
