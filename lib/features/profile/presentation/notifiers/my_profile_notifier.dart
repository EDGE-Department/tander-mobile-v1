import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/profile/domain/repositories/profile_repository.dart';
import 'package:tander_flutter_v3/features/profile/presentation/providers/profile_providers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/states/profile_state.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final myProfileNotifierProvider =
    NotifierProvider<MyProfileNotifier, ProfileState>(MyProfileNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the authenticated user's profile state.
///
/// Delegates all IO to [ProfileRepository] and translates [Result] outcomes
/// into the sealed [ProfileState] hierarchy so the UI can do exhaustive
/// switches.
final class MyProfileNotifier extends Notifier<ProfileState> {
  // `late`, not `late final`: Notifier.build() re-runs on invalidate/refresh
  // (incl. config changes like font-scale); re-assigning a final field throws
  // LateInitializationError.
  late ProfileRepository _repository;

  static const String _tag = 'MyProfileNotifier';

  @override
  ProfileState build() {
    _repository = ref.read(profileRepositoryProvider);

    // Auto-fetch profile on first access.
    Future.microtask(fetchProfile);

    return const ProfileLoading();
  }

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetches the authenticated user's profile from the server.
  ///
  /// Transitions to [ProfileLoaded] on success, [ProfileError] on failure.
  Future<void> fetchProfile() async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      state = const ProfileLoading();
    }

    final fetchResult = await _repository.fetchMyProfile();

    fetchResult.when(
      success: (profile) {
        state = ProfileLoaded(profile: profile);
        AppLogger.debug(
          'Profile loaded for user ${profile.userId}',
          operation: _tag,
        );
      },
      failure: (exception) {
        state = ProfileError(exception: exception);
        AppLogger.error(
          'Failed to fetch profile',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// Updates the authenticated user's profile, then re-fetches to sync state.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> updateProfile(UpdateProfileRequestDto request) async {
    final updateResult = await _repository.updateProfile(request: request);

    return updateResult.when(
      success: (updatedProfile) {
        state = ProfileLoaded(profile: updatedProfile);
        AppLogger.debug('Profile updated', operation: _tag);
        return true;
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to update profile',
          operation: _tag,
          error: exception,
        );
        return false;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Photo operations
  // ---------------------------------------------------------------------------

  /// Uploads a new profile photo, then re-fetches profile to reflect the change.
  Future<bool> uploadProfilePhoto(String filePath) async {
    final uploadResult = await _repository.uploadProfilePhoto(
      filePath: filePath,
    );

    return uploadResult.when(
      success: (_) {
        AppLogger.debug('Profile photo uploaded', operation: _tag);
        Future.microtask(fetchProfile);
        return true;
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to upload profile photo',
          operation: _tag,
          error: exception,
        );
        return false;
      },
    );
  }

  /// Uploads additional photos, then re-fetches profile to reflect the change.
  Future<bool> uploadAdditionalPhotos(List<String> filePaths) async {
    final uploadResult = await _repository.uploadAdditionalPhotos(
      filePaths: filePaths,
    );

    return uploadResult.when(
      success: (_) {
        AppLogger.debug('Additional photos uploaded', operation: _tag);
        Future.microtask(fetchProfile);
        return true;
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to upload additional photos',
          operation: _tag,
          error: exception,
        );
        return false;
      },
    );
  }

  /// Deletes a photo by gallery index, then re-fetches profile.
  /// Index 0 = main profile photo, index 1+ = additional photos.
  Future<bool> deletePhoto(int galleryIndex) async {
    final deleteResult = await _repository.deletePhoto(
      galleryIndex: galleryIndex,
    );

    return deleteResult.when(
      success: (_) {
        AppLogger.debug('Photo deleted', operation: _tag);
        Future.microtask(fetchProfile);
        return true;
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to delete photo',
          operation: _tag,
          error: exception,
        );
        return false;
      },
    );
  }

  /// Reorders photos, then re-fetches profile to reflect the change.
  Future<bool> reorderPhotos(List<String> photoUrls) async {
    final reorderResult = await _repository.reorderPhotos(photoUrls: photoUrls);

    return reorderResult.when(
      success: (_) {
        AppLogger.debug('Photos reordered', operation: _tag);
        Future.microtask(fetchProfile);
        return true;
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to reorder photos',
          operation: _tag,
          error: exception,
        );
        return false;
      },
    );
  }
}
