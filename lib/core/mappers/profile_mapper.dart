import 'dart:convert';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';

/// Pure functions converting profile DTOs to domain models.
///
/// All conversions are null-safe with documented fallback behaviour.
/// The mapper never performs I/O or mutates external state.
abstract final class ProfileMapper {
  /// Maps a [UserProfileDto] (raw backend shape) to a [UserProfile] domain model.
  ///
  /// CRITICAL: `interests`, `lookingFor`, and `languages` arrive from the backend
  /// as JSON-encoded strings (e.g. `'["Cooking","Reading"]'`). The mapper parses
  /// them into `List<String>`. `additionalPhotos` is already a `List<String>`.
  static UserProfile mapUserProfileDto(UserProfileDto dto) {
    return UserProfile(
      userId: dto.id.toString(),
      username: dto.username,
      firstName: dto.firstName ?? '',
      middleName: dto.middleName,
      lastName: dto.lastName,
      nickName: dto.nickName,
      displayName: dto.displayName,
      email: dto.email,
      dateOfBirth: _parseDateOfBirth(dto.birthDate),
      age: dto.age,
      gender: dto.gender,
      bio: dto.bio,
      city: dto.city,
      country: dto.country,
      civilStatus: dto.civilStatus,
      profilePhotoUrl: dto.profilePhotoUrl,
      additionalPhotos: dto.additionalPhotos ?? const [],
      interests: parseJsonStringArray(dto.interests),
      lookingFor: parseJsonStringArray(dto.lookingFor),
      hobby: dto.hobby,
      interestedIn: dto.interestedIn,
      religion: dto.religion,
      numberOfChildren: dto.numberOfChildren,
      languages: parseJsonStringArray(dto.languages),
      maritalStatus: dto.maritalStatus,
      isOnline: false,
      isVerified: dto.verified ?? false,
      isProfileCompleted: dto.profileCompleted ?? false,
    );
  }

  /// Maps a [NotificationSettingsDto] to domain [NotificationSettings].
  static NotificationSettings mapNotificationSettingsDto(
    NotificationSettingsDto dto,
  ) {
    return NotificationSettings(
      hasNewMessageNotifs: dto.newMessages,
      hasNewConnectionNotifs: dto.newConnections,
      hasCommunityActivityNotifs: dto.communityActivity,
      hasTandyReminders: dto.tandyReminders,
      hasCallNotifications: dto.callNotifications,
      hasEmailNotifications: dto.emailNotifications,
    );
  }

  /// Maps a [PrivacySettingsDto] to domain [PrivacySettings].
  static PrivacySettings mapPrivacySettingsDto(PrivacySettingsDto dto) {
    return PrivacySettings(
      profileVisibility: dto.profileVisibility,
      showsOnlineStatus: dto.showOnlineStatus,
      showsLastSeen: dto.showLastSeen,
      allowsConnectionRequests: dto.allowConnectionRequests,
    );
  }

  /// Maps a [SecuritySettingsDto] to domain [SecuritySettings].
  static SecuritySettings mapSecuritySettingsDto(SecuritySettingsDto dto) {
    return SecuritySettings(
      isTwoFactorEnabled: dto.twoFactorEnabled,
      activeSessions: dto.activeSessions
          .map(_mapActiveSessionDto)
          .toList(growable: false),
    );
  }

  /// Maps a [DiscoverySettingsDto] to domain [DiscoverySettings].
  static DiscoverySettings mapDiscoverySettingsDto(DiscoverySettingsDto dto) {
    return DiscoverySettings(
      isDiscoverable: dto.isDiscoverable,
      minAge: dto.minAge,
      maxAge: dto.maxAge,
      maxDistanceKm: dto.maxDistanceKm,
      genderPreference: dto.genderPreference,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static ActiveSession _mapActiveSessionDto(ActiveSessionDto dto) {
    return ActiveSession(
      sessionId: dto.sessionId,
      device: dto.device,
      lastActiveAt: DateTime.parse(dto.lastActiveAt),
      isCurrent: dto.isCurrent,
    );
  }

  /// Parses a date-of-birth string into a [DateTime].
  ///
  /// Returns `null` if the string is null, empty, or unparseable.
  static DateTime? _parseDateOfBirth(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return null;
    return DateTime.tryParse(rawDate);
  }

  /// Backend stores interests/lookingFor/languages as JSON-encoded strings
  /// in the DB. The `/user/me` endpoint puts them into the response as raw
  /// strings like `'["A","B"]'`.
  ///
  /// This parser handles:
  /// - JSON array string (`'["A","B"]'`)
  /// - Comma-separated string (`'A,B'`)
  /// - Null or empty string (returns `[]`)
  /// - Malformed JSON (falls back to comma split)
  static List<String> parseJsonStringArray(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return const [];

    final trimmed = jsonString.trim();
    if (trimmed.isEmpty) return const [];

    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded.whereType<String>().toList(growable: false);
        }
      } on FormatException {
        // Fall through to comma split
      }
    }

    return trimmed
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  }
}
