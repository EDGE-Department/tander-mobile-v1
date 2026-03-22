/// Pure utility functions for profile presentation logic.
///
/// Stateless helpers for computing completion scores, tier labels,
/// and display formatting. No side effects, no imports beyond the
/// domain model.
library;

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';

// ── Constants ─────────────────────────────────────────────────────────────

/// Labels for the `lookingFor` backend values.
const Map<String, String> lookingForLabels = {
  'FRIENDSHIP': 'Friendship',
  'COMPANIONSHIP': 'Companionship',
  'ROMANCE': 'Romance',
  'ACTIVITY_BUDDY': 'Activity buddy',
};

/// Minimum interest count to earn the interests completion bonus.
const int minInterestsForCompletion = 3;

/// Minimum photo count to earn the photos bonus.
const int minPhotosForBonus = 3;

/// Maximum number of photos a user may upload.
const int maxPhotos = 6;

// ── Helpers ───────────────────────────────────────────────────────────────

/// Pure profile utility functions.
///
/// All methods are static, side-effect-free, and testable in isolation.
abstract final class ProfileHelpers {
  /// Computes profile completion as a 0-100 integer.
  ///
  /// Scoring mirrors the web application's `computeCompletionPercent`:
  ///   - First name filled:     +10
  ///   - Age >= 18:             +10
  ///   - City or country:       +10
  ///   - Bio present:           +20
  ///   - At least 1 photo:      +15
  ///   - >= 3 photos:           +10
  ///   - >= 3 interests:        +15
  ///   - Gender set:            +10
  static int computeCompletionPercent(UserProfile profile) {
    final int photoCount = _countGalleryPhotos(profile);
    int score = 0;

    if (profile.firstName.trim().isNotEmpty) score += 10;
    if (profile.age != null && profile.age! >= 18) score += 10;
    if (_hasLocation(profile)) score += 10;
    if ((profile.bio ?? '').trim().isNotEmpty) score += 20;
    if (photoCount > 0) score += 15;
    if (photoCount >= minPhotosForBonus) score += 10;
    if (profile.interests.length >= minInterestsForCompletion) score += 15;
    if ((profile.gender ?? '').trim().isNotEmpty) score += 10;

    return score.clamp(0, 100);
  }

  /// Returns a human-readable tier label for the given [percent].
  static String completionTierLabel(int percent) {
    if (percent >= 100) return 'Profile Star';
    if (percent >= 85) return 'Almost There';
    if (percent >= 60) return 'Rising Star';
    if (percent >= 35) return 'Building Up';
    return 'Just Starting';
  }

  /// Joins a list of looking-for backend values into a display string,
  /// or returns `null` when the list is empty or `null`.
  static String? formatLookingFor(List<String>? values) {
    if (values == null || values.isEmpty) return null;
    return values
        .map((item) =>
            lookingForLabels[item] ?? toTitleCase(item.replaceAll('_', ' ')))
        .join(', ');
  }

  /// Title-cases every word in [input]: `"hello world"` -> `"Hello World"`.
  static String toTitleCase(String input) {
    return input
        .toLowerCase()
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Builds a deduplicated list of all photo URLs for a profile.
  static List<String> buildGallery(UserProfile profile) {
    final Set<String> seen = {};
    final List<String> gallery = [];

    void addIfPresent(String? url) {
      if (url != null && url.trim().isNotEmpty && seen.add(url)) {
        gallery.add(url);
      }
    }

    addIfPresent(profile.profilePhotoUrl);
    for (final url in profile.additionalPhotos) {
      addIfPresent(url);
    }
    return gallery;
  }

  /// Builds a display name from profile name parts, falling back to username.
  static String buildDisplayName(UserProfile profile) {
    final parts = [profile.firstName, profile.middleName, profile.lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => toTitleCase(part!))
        .toList();

    return parts.isNotEmpty ? parts.join(' ') : profile.username;
  }

  /// Builds a location string from city and country, or empty string.
  static String buildDisplayLocation(UserProfile profile) {
    return [profile.city, profile.country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
  }

  // ── Private helpers ──────────────────────────────────────────────────

  static bool _hasLocation(UserProfile profile) {
    return (profile.city ?? '').trim().isNotEmpty ||
        (profile.country ?? '').trim().isNotEmpty;
  }

  static int _countGalleryPhotos(UserProfile profile) {
    return buildGallery(profile).length;
  }
}
