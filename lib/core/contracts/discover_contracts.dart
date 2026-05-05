/// Discovery domain -- raw backend DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

part 'discover_contracts.g.dart';

// ---------------------------------------------------------------------------
// Discovery profile
// ---------------------------------------------------------------------------

/// Mirrors DiscoveryProfileDTO.java -- Lombok @Data with boolean `is*` fields
/// serialize as `online`, `verified`, `matched`, etc. (Jackson strips `is`
/// prefix).
@JsonSerializable()
class DiscoveryProfileDto {
  const DiscoveryProfileDto({
    required this.userId,
    required this.username,
    required this.verified,
    required this.online,
    required this.hasBeenSwiped,
    required this.hasLikedMe,
    required this.matched,
    this.displayName,
    this.age,
    this.city,
    this.country,
    this.location,
    this.bio,
    this.profilePhotoUrl,
    this.additionalPhotos,
    this.interests,
    this.lookingFor,
    this.compatibilityScore,
    this.distanceKm,
  });

  factory DiscoveryProfileDto.fromJson(Map<String, Object?> json) =>
      _$DiscoveryProfileDtoFromJson(json);

  final String userId;
  final String username;
  final String? displayName;
  final int? age;
  final String? city;
  final String? country;
  final String? location;
  final String? bio;
  final String? profilePhotoUrl;
  final List<String>? additionalPhotos;

  /// Discovery endpoint parses these into actual arrays (unlike /user/me).
  final List<String>? interests;
  final List<String>? lookingFor;

  final bool verified;
  final bool online;
  final bool hasBeenSwiped;
  final bool hasLikedMe;
  final bool matched;
  final double? compatibilityScore;
  final double? distanceKm;

  Map<String, Object?> toJson() => _$DiscoveryProfileDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Discovery filters
// ---------------------------------------------------------------------------

@JsonSerializable()
class DiscoveryFiltersDto {
  const DiscoveryFiltersDto({
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceKm,
    this.genderPreference,
    this.lookingFor,
  });

  factory DiscoveryFiltersDto.fromJson(Map<String, Object?> json) =>
      _$DiscoveryFiltersDtoFromJson(json);

  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final String? genderPreference;
  final String? lookingFor;

  Map<String, Object?> toJson() => _$DiscoveryFiltersDtoToJson(this);
}
