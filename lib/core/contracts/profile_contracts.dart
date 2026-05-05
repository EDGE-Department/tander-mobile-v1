/// Profile domain -- raw backend DTOs.
library;

import 'package:json_annotation/json_annotation.dart';

part 'profile_contracts.g.dart';

// ---------------------------------------------------------------------------
// User profile
// ---------------------------------------------------------------------------

@JsonSerializable()
class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.userId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.nickName,
    this.displayName,
    this.email,
    this.age,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.city,
    this.country,
    this.civilStatus,
    this.maritalStatus,
    this.religion,
    this.numberOfChildren,
    this.hobby,
    this.interestedIn,
    this.interests,
    this.lookingFor,
    this.languages,
    this.profilePhotoUrl,
    this.additionalPhotos,
    this.verified,
    this.profileCompleted,
  });

  factory UserProfileDto.fromJson(Map<String, Object?> json) =>
      _$UserProfileDtoFromJson(json);

  final int id;
  final String userId;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? nickName;
  final String? displayName;
  final String? email;
  final int? age;
  final String? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? city;
  final String? country;
  final String? civilStatus;
  final String? maritalStatus;
  final String? religion;
  final int? numberOfChildren;
  final String? hobby;
  final String? interestedIn;
  final List<String>? interests;
  final List<String>? lookingFor;
  final List<String>? languages;
  final String? profilePhotoUrl;
  final List<String>? additionalPhotos;
  final bool? verified;
  final bool? profileCompleted;

  Map<String, Object?> toJson() => _$UserProfileDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Settings DTOs
// ---------------------------------------------------------------------------

@JsonSerializable()
class UserSettingsDto {
  const UserSettingsDto({
    required this.showOnline,
    required this.showLastSeen,
    required this.showProfileViews,
    required this.showAge,
    required this.readReceipts,
    required this.profileVisibility,
    required this.discoveryVisible,
    required this.discoveryMinAge,
    required this.discoveryMaxAge,
    required this.discoveryMaxDistanceKm,
    required this.notifyMessages,
    required this.notifyMatches,
    required this.notifyProfileViews,
    required this.notifyCommunity,
    required this.notifyTandy,
    required this.notifyCalls,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.twoFactorEnabled,
    required this.consentMarketing,
    required this.consentAdPersonalization,
    required this.consentTandyMemory,
    this.familyAlertContactPhone,
    this.familyAlertContactLabel,
  });

  factory UserSettingsDto.fromJson(Map<String, Object?> json) =>
      _$UserSettingsDtoFromJson(json);

  final bool showOnline;
  final bool showLastSeen;
  final bool showProfileViews;
  final bool showAge;
  final bool readReceipts;
  final String profileVisibility;
  final bool discoveryVisible;
  final int discoveryMinAge;
  final int discoveryMaxAge;
  final int discoveryMaxDistanceKm;
  final bool notifyMessages;
  final bool notifyMatches;
  final bool notifyProfileViews;
  final bool notifyCommunity;
  final bool notifyTandy;
  final bool notifyCalls;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool twoFactorEnabled;
  final bool consentMarketing;
  final bool consentAdPersonalization;
  final bool consentTandyMemory;
  final String? familyAlertContactPhone;
  final String? familyAlertContactLabel;

  Map<String, Object?> toJson() => _$UserSettingsDtoToJson(this);
}

@JsonSerializable(includeIfNull: false)
class UpdateSettingsRequestDto {
  const UpdateSettingsRequestDto({
    this.showOnline,
    this.showLastSeen,
    this.showProfileViews,
    this.showAge,
    this.readReceipts,
    this.profileVisibility,
    this.discoveryVisible,
    this.discoveryMinAge,
    this.discoveryMaxAge,
    this.discoveryMaxDistanceKm,
    this.notifyMessages,
    this.notifyMatches,
    this.notifyProfileViews,
    this.notifyCommunity,
    this.notifyTandy,
    this.notifyCalls,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.quietHoursStartSet,
    this.quietHoursEndSet,
    this.twoFactorEnabled,
    this.consentMarketing,
    this.consentAdPersonalization,
    this.consentTandyMemory,
  });

  factory UpdateSettingsRequestDto.fromJson(Map<String, Object?> json) =>
      _$UpdateSettingsRequestDtoFromJson(json);

  final bool? showOnline;
  final bool? showLastSeen;
  final bool? showProfileViews;
  final bool? showAge;
  final bool? readReceipts;
  final String? profileVisibility;
  final bool? discoveryVisible;
  final int? discoveryMinAge;
  final int? discoveryMaxAge;
  final int? discoveryMaxDistanceKm;
  final bool? notifyMessages;
  final bool? notifyMatches;
  final bool? notifyProfileViews;
  final bool? notifyCommunity;
  final bool? notifyTandy;
  final bool? notifyCalls;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool? quietHoursStartSet;
  final bool? quietHoursEndSet;
  final bool? twoFactorEnabled;
  final bool? consentMarketing;
  final bool? consentAdPersonalization;
  final bool? consentTandyMemory;

  Map<String, Object?> toJson() => _$UpdateSettingsRequestDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Other
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
