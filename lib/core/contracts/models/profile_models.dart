/// Profile domain models — consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
library;

import 'package:flutter/foundation.dart';

// ── Visibility & Settings ────────────────────────────────────

/// Controls who can see a user's profile.
const profileVisibilityPublic = 'PUBLIC';
const profileVisibilityConnectionsOnly = 'CONNECTIONS_ONLY';
const profileVisibilityPrivate = 'PRIVATE';

typedef ProfileVisibility = String;

// ── Core Profile ─────────────────────────────────────────────

@immutable
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.username,
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
  final String username;
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
  String toString() => 'UserProfile(userId: $userId, username: $username)';
}

// ── Settings Models ──────────────────────────────────────────

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettings &&
          runtimeType == other.runtimeType &&
          hasNewMessageNotifs == other.hasNewMessageNotifs &&
          hasNewConnectionNotifs == other.hasNewConnectionNotifs &&
          hasCommunityActivityNotifs == other.hasCommunityActivityNotifs &&
          hasTandyReminders == other.hasTandyReminders &&
          hasCallNotifications == other.hasCallNotifications &&
          hasEmailNotifications == other.hasEmailNotifications;

  @override
  int get hashCode => Object.hash(
        hasNewMessageNotifs,
        hasNewConnectionNotifs,
        hasCommunityActivityNotifs,
        hasTandyReminders,
        hasCallNotifications,
        hasEmailNotifications,
      );

  @override
  String toString() => 'NotificationSettings('
      'messages: $hasNewMessageNotifs, '
      'connections: $hasNewConnectionNotifs)';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacySettings &&
          runtimeType == other.runtimeType &&
          profileVisibility == other.profileVisibility &&
          showsOnlineStatus == other.showsOnlineStatus &&
          showsLastSeen == other.showsLastSeen &&
          allowsConnectionRequests == other.allowsConnectionRequests;

  @override
  int get hashCode => Object.hash(
        profileVisibility,
        showsOnlineStatus,
        showsLastSeen,
        allowsConnectionRequests,
      );

  @override
  String toString() =>
      'PrivacySettings(visibility: $profileVisibility)';
}

@immutable
class SecuritySettings {
  const SecuritySettings({
    required this.isTwoFactorEnabled,
    required this.activeSessions,
  });

  final bool isTwoFactorEnabled;
  final List<ActiveSession> activeSessions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecuritySettings &&
          runtimeType == other.runtimeType &&
          isTwoFactorEnabled == other.isTwoFactorEnabled;

  @override
  int get hashCode => isTwoFactorEnabled.hashCode;

  @override
  String toString() => 'SecuritySettings('
      'twoFactor: $isTwoFactorEnabled, '
      'sessions: ${activeSessions.length})';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;

  @override
  String toString() =>
      'ActiveSession(id: $sessionId, device: $device)';
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoverySettings &&
          runtimeType == other.runtimeType &&
          isDiscoverable == other.isDiscoverable &&
          minAge == other.minAge &&
          maxAge == other.maxAge &&
          maxDistanceKm == other.maxDistanceKm &&
          genderPreference == other.genderPreference;

  @override
  int get hashCode => Object.hash(
        isDiscoverable,
        minAge,
        maxAge,
        maxDistanceKm,
        genderPreference,
      );

  @override
  String toString() => 'DiscoverySettings('
      'discoverable: $isDiscoverable, '
      'age: $minAge-$maxAge, '
      'distance: ${maxDistanceKm}km)';
}
