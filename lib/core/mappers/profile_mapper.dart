import 'dart:convert';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';

/// Pure functions converting profile DTOs to domain models.
///
/// All conversions are null-safe with documented fallback behaviour.
/// The mapper never performs I/O or mutates external state.
abstract final class ProfileMapper {
  /// Maps a [UserProfileDto] (raw backend shape) to a [UserProfile] domain model.
  static UserProfile mapUserProfileDto(UserProfileDto dto) {
    return UserProfile(
      userId: dto.userId,
      firstName: dto.firstName ?? '',
      middleName: dto.middleName,
      lastName: dto.lastName,
      nickName: dto.nickName,
      displayName: dto.displayName,
      email: dto.email,
      dateOfBirth: _parseDateOfBirth(dto.dateOfBirth),
      age: dto.age,
      gender: dto.gender,
      bio: dto.bio,
      city: dto.city,
      country: dto.country,
      civilStatus: dto.civilStatus,
      profilePhotoUrl: dto.profilePhotoUrl,
      additionalPhotos: dto.additionalPhotos ?? const [],
      interests: dto.interests ?? const [],
      lookingFor: dto.lookingFor ?? const [],
      hobby: dto.hobby,
      interestedIn: dto.interestedIn,
      religion: dto.religion,
      numberOfChildren: dto.numberOfChildren,
      languages: dto.languages ?? const [],
      maritalStatus: dto.maritalStatus,
      isOnline: false,
      isVerified: dto.verified ?? false,
      isProfileCompleted: dto.profileCompleted ?? false,
    );
  }

  /// Maps a [UserSettingsDto] to domain [UserSettings].
  static UserSettings mapUserSettingsDto(UserSettingsDto dto) {
    return UserSettings(
      showOnline: dto.showOnline,
      showLastSeen: dto.showLastSeen,
      showProfileViews: dto.showProfileViews,
      showAge: dto.showAge,
      readReceipts: dto.readReceipts,
      profileVisibility: dto.profileVisibility,
      discoveryVisible: dto.discoveryVisible,
      discoveryMinAge: dto.discoveryMinAge,
      discoveryMaxAge: dto.discoveryMaxAge,
      discoveryMaxDistanceKm: dto.discoveryMaxDistanceKm,
      notifyMessages: dto.notifyMessages,
      notifyMatches: dto.notifyMatches,
      notifyProfileViews: dto.notifyProfileViews,
      notifyCommunity: dto.notifyCommunity,
      notifyTandy: dto.notifyTandy,
      notifyCalls: dto.notifyCalls,
      quietHoursStart: dto.quietHoursStart,
      quietHoursEnd: dto.quietHoursEnd,
      twoFactorEnabled: dto.twoFactorEnabled,
      consentMarketing: dto.consentMarketing,
      consentAdPersonalization: dto.consentAdPersonalization,
      consentTandyMemory: dto.consentTandyMemory,
      familyAlertContactPhone: dto.familyAlertContactPhone,
      familyAlertContactLabel: dto.familyAlertContactLabel,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Parses a date-of-birth string into a [DateTime].
  ///
  /// Returns `null` if the string is null, empty, or unparseable.
  static DateTime? _parseDateOfBirth(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return null;
    return DateTime.tryParse(rawDate);
  }

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
      } on FormatException { /* fall through */ }
    }
    return trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
