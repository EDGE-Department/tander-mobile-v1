/// Discovery domain models — consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
library;

import 'package:flutter/foundation.dart';

// ── Discovery Candidate ──────────────────────────────────────

@immutable
class DiscoveryCandidate {
  const DiscoveryCandidate({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.isOnline,
    required this.hasExistingConnection,
    required this.additionalPhotos,
    required this.interests,
    this.age,
    this.city,
    this.country,
    this.bio,
    this.profilePhotoUrl,
  });

  final String userId;
  final String username;
  final String firstName;
  final int? age;
  final String? city;
  final String? country;
  final String? bio;
  final String? profilePhotoUrl;
  final List<String> additionalPhotos;
  final List<String> interests;
  final bool isOnline;
  final bool hasExistingConnection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryCandidate &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'DiscoveryCandidate('
      'userId: $userId, '
      'name: $firstName)';
}

// ── Discovery Filters ────────────────────────────────────────

@immutable
class DiscoveryFilters {
  const DiscoveryFilters({
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceKm,
    this.genderPreference,
    this.lookingFor,
  });

  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final String? genderPreference;
  final String? lookingFor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryFilters &&
          runtimeType == other.runtimeType &&
          minAge == other.minAge &&
          maxAge == other.maxAge &&
          maxDistanceKm == other.maxDistanceKm &&
          genderPreference == other.genderPreference &&
          lookingFor == other.lookingFor;

  @override
  int get hashCode =>
      Object.hash(minAge, maxAge, maxDistanceKm, genderPreference, lookingFor);

  @override
  String toString() =>
      'DiscoveryFilters('
      'age: $minAge-$maxAge, '
      'distance: ${maxDistanceKm}km)';
}
