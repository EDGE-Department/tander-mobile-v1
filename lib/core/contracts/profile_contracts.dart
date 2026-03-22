/// Profile domain -- raw backend DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

part 'profile_contracts.g.dart';

// ---------------------------------------------------------------------------
// User profile
// ---------------------------------------------------------------------------

/// Mirrors the JSON Map built by UserController#getCurrentUser (/user/me)
/// and UserController#getUserById (/user/{userId}).
///
/// Backend stores interests, lookingFor, and languages as JSON-encoded strings
/// in the DB. The /me endpoint puts them into the response as raw strings
/// (NOT parsed arrays). additionalPhotos IS parsed into a List<String>.
@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.username,
    this.firstName,
    this.middleName,
    this.lastName,
    this.nickName,
    this.displayName,
    this.email,
    this.age,
    this.birthDate,
    this.gender,
    this.bio,
    this.city,
    this.country,
    this.civilStatus,
    this.hobby,
    this.profilePhotoUrl,
    this.additionalPhotos,
    this.interests,
    this.lookingFor,
    this.interestedIn,
    this.religion,
    this.numberOfChildren,
    this.languages,
    this.maritalStatus,
    this.verified,
    this.profileCompleted,
  });

  factory UserProfileDto.fromJson(Map<String, Object?> json) =>
      _$UserProfileDtoFromJson(json);

  final int id;
  final String username;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? nickName;
  final String? displayName;
  final String? email;
  final int? age;
  final String? birthDate;
  final String? gender;
  final String? bio;
  final String? city;
  final String? country;
  final String? civilStatus;
  final String? hobby;
  final String? profilePhotoUrl;

  /// Already parsed from JSON string by backend.
  final List<String>? additionalPhotos;

  /// Raw JSON string from DB -- e.g. '["Reading","Cooking"]'
  final String? interests;

  /// Raw JSON string from DB -- e.g. '["Friendship"]'
  final String? lookingFor;

  final String? interestedIn;
  final String? religion;
  final int? numberOfChildren;

  /// Raw JSON string from DB -- e.g. '["Tagalog","English"]'
  final String? languages;

  final String? maritalStatus;

  /// ID-verification status (from UserIdentityVerification).
  final bool? verified;
  final bool? profileCompleted;

  Map<String, Object?> toJson() => _$UserProfileDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Update profile
// ---------------------------------------------------------------------------

@JsonSerializable(includeIfNull: false)
class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({
    this.firstName,
    this.middleName,
    this.lastName,
    this.nickName,
    this.bio,
    this.city,
    this.country,
    this.civilStatus,
    this.interests,
    this.lookingFor,
    this.birthDate,
    this.age,
    this.gender,
    this.interestedIn,
    this.hobby,
    this.religion,
    this.numberOfChildren,
    this.languages,
    this.maritalStatus,
  });

  factory UpdateProfileRequestDto.fromJson(Map<String, Object?> json) =>
      _$UpdateProfileRequestDtoFromJson(json);

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? nickName;
  final String? bio;
  final String? city;
  final String? country;
  final String? civilStatus;
  final String? interests;
  final String? lookingFor;
  final String? birthDate;
  final int? age;
  final String? gender;
  final String? interestedIn;
  final String? hobby;
  final String? religion;
  final int? numberOfChildren;
  final String? languages;
  final String? maritalStatus;

  Map<String, Object?> toJson() => _$UpdateProfileRequestDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Settings DTOs
// ---------------------------------------------------------------------------

@JsonSerializable()
class NotificationSettingsDto {
  const NotificationSettingsDto({
    required this.newMessages,
    required this.newConnections,
    required this.communityActivity,
    required this.tandyReminders,
    required this.callNotifications,
    required this.emailNotifications,
  });

  factory NotificationSettingsDto.fromJson(Map<String, Object?> json) =>
      _$NotificationSettingsDtoFromJson(json);

  final bool newMessages;
  final bool newConnections;
  final bool communityActivity;
  final bool tandyReminders;
  final bool callNotifications;
  final bool emailNotifications;

  Map<String, Object?> toJson() => _$NotificationSettingsDtoToJson(this);
}

@JsonSerializable()
class PrivacySettingsDto {
  const PrivacySettingsDto({
    required this.profileVisibility,
    required this.showOnlineStatus,
    required this.showLastSeen,
    required this.allowConnectionRequests,
  });

  factory PrivacySettingsDto.fromJson(Map<String, Object?> json) =>
      _$PrivacySettingsDtoFromJson(json);

  /// 'PUBLIC', 'CONNECTIONS_ONLY', or 'PRIVATE'
  final String profileVisibility;
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool allowConnectionRequests;

  Map<String, Object?> toJson() => _$PrivacySettingsDtoToJson(this);
}

@JsonSerializable()
class ActiveSessionDto {
  const ActiveSessionDto({
    required this.sessionId,
    required this.device,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  factory ActiveSessionDto.fromJson(Map<String, Object?> json) =>
      _$ActiveSessionDtoFromJson(json);

  final String sessionId;
  final String device;
  final String lastActiveAt;
  final bool isCurrent;

  Map<String, Object?> toJson() => _$ActiveSessionDtoToJson(this);
}

@JsonSerializable()
class SecuritySettingsDto {
  const SecuritySettingsDto({
    required this.twoFactorEnabled,
    required this.activeSessions,
  });

  factory SecuritySettingsDto.fromJson(Map<String, Object?> json) =>
      _$SecuritySettingsDtoFromJson(json);

  final bool twoFactorEnabled;
  final List<ActiveSessionDto> activeSessions;

  Map<String, Object?> toJson() => _$SecuritySettingsDtoToJson(this);
}

@JsonSerializable()
class DiscoverySettingsDto {
  const DiscoverySettingsDto({
    required this.isDiscoverable,
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceKm,
    this.genderPreference,
  });

  factory DiscoverySettingsDto.fromJson(Map<String, Object?> json) =>
      _$DiscoverySettingsDtoFromJson(json);

  final bool isDiscoverable;
  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final String? genderPreference;

  Map<String, Object?> toJson() => _$DiscoverySettingsDtoToJson(this);
}

@JsonSerializable()
class ChangePasswordRequestDto {
  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequestDto.fromJson(Map<String, Object?> json) =>
      _$ChangePasswordRequestDtoFromJson(json);

  final String currentPassword;
  final String newPassword;

  Map<String, Object?> toJson() => _$ChangePasswordRequestDtoToJson(this);
}
