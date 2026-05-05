/// Profile domain models — consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
library;

import 'package:flutter/foundation.dart';

// ── Visibility & Settings ────────────────────────────────────

/// Controls who can see a user's profile.
const profileVisibilityPublic = 'PUBLIC';
const profileVisibilityMatchesOnly = 'MATCHES_ONLY';
const profileVisibilityPrivate = 'PRIVATE';

typedef ProfileVisibility = String;

// ── Core Profile ─────────────────────────────────────────────

@immutable
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.firstName,
    required this.isOnline,
    required this.isVerified,
    required this.isProfileCompleted,
    required this.additionalPhotos,
    required this.interests,
    required this.lookingFor,
    required this.languages,
    this.middleName,
    this.lastName,
    this.nickName,
    this.displayName,
    this.email,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.bio,
    this.city,
    this.country,
    this.civilStatus,
    this.profilePhotoUrl,
    this.hobby,
    this.interestedIn,
    this.religion,
    this.numberOfChildren,
    this.maritalStatus,
  });

  final String userId;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? nickName;
  final String? displayName;
  final String? email;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;
  final String? bio;
  final String? city;
  final String? country;
  final String? civilStatus;
  final String? profilePhotoUrl;
  final List<String> additionalPhotos;
  final List<String> interests;
  final List<String> lookingFor;
  final String? hobby;
  final String? interestedIn;
  final String? religion;
  final int? numberOfChildren;
  final List<String> languages;
  final String? maritalStatus;
  final bool isOnline;
  final bool isVerified;
  final bool isProfileCompleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'UserProfile(userId: $userId, firstName: $firstName)';
}

// ── Settings Models ──────────────────────────────────────────

@immutable
class UserSettings {
  const UserSettings({
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

  final bool showOnline;
  final bool showLastSeen;
  final bool showProfileViews;
  final bool showAge;
  final bool readReceipts;
  final ProfileVisibility profileVisibility;
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
}

@immutable
class NotificationSettings {
  const NotificationSettings({
    required this.hasNewMessageNotifs,
    required this.hasNewConnectionNotifs,
    required this.hasCommunityActivityNotifs,
    required this.hasTandyReminders,
    required this.hasCallNotifications,
    required this.hasEmailNotifications,
  });

  final bool hasNewMessageNotifs;
  final bool hasNewConnectionNotifs;
  final bool hasCommunityActivityNotifs;
  final bool hasTandyReminders;
  final bool hasCallNotifications;
  final bool hasEmailNotifications;
}

@immutable
class PrivacySettings {
  const PrivacySettings({
    required this.profileVisibility,
    required this.showsOnlineStatus,
    required this.showsLastSeen,
    required this.allowsConnectionRequests,
  });

  final ProfileVisibility profileVisibility;
  final bool showsOnlineStatus;
  final bool showsLastSeen;
  final bool allowsConnectionRequests;
}

@immutable
class SecuritySettings {
  const SecuritySettings({
    required this.isTwoFactorEnabled,
    required this.activeSessions,
  });

  final bool isTwoFactorEnabled;
  final List<ActiveSession> activeSessions;
}

@immutable
class ActiveSession {
  const ActiveSession({
    required this.sessionId,
    required this.device,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  final String sessionId;
  final String device;
  final DateTime lastActiveAt;
  final bool isCurrent;
}

@immutable
class DiscoverySettings {
  const DiscoverySettings({
    required this.isDiscoverable,
    required this.minAge,
    required this.maxAge,
    required this.maxDistanceKm,
    this.genderPreference,
  });

  final bool isDiscoverable;
  final int minAge;
  final int maxAge;
  final int maxDistanceKm;
  final String? genderPreference;
}
