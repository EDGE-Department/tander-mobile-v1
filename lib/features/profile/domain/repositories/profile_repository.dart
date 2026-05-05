import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

/// Contract for all profile operations.
///
/// Implementations live in the data layer and may use Dio, secure storage, or
/// any other infrastructure concern. The domain and presentation layers only
/// know this interface.
abstract interface class ProfileRepository {
  // ---------------------------------------------------------------------------
  // Profile CRUD
  // ---------------------------------------------------------------------------

  /// Fetches the authenticated user's profile.
  Future<Result<UserProfile>> fetchMyProfile();

  /// Fetches another user's profile by their [userId].
  Future<Result<UserProfile>> fetchUserProfile({required int userId});

  /// Updates the authenticated user's profile.
  Future<Result<UserProfile>> updateProfile({
    required UpdateProfileRequestDto request,
  });

  // ---------------------------------------------------------------------------
  // Photo management
  // ---------------------------------------------------------------------------

  /// Uploads a new profile photo from the file at [filePath].
  Future<Result<void>> uploadProfilePhoto({required String filePath});

  /// Uploads additional gallery photos from the files at [filePaths].
  Future<Result<void>> uploadAdditionalPhotos({
    required List<String> filePaths,
  });

  /// Deletes a photo by its gallery index.
  /// Index 0 = main profile photo, index 1+ = additional photos.
  Future<Result<void>> deletePhoto({required int galleryIndex});

  /// Reorders gallery photos to match the given [photoUrls] order.
  Future<Result<void>> reorderPhotos({required List<String> photoUrls});

  // ---------------------------------------------------------------------------
  // Settings (Unified)
  // ---------------------------------------------------------------------------

  Future<Result<UserSettings>> fetchUserSettings();

  Future<Result<void>> updateUserSettings({
    required UpdateSettingsRequestDto request,
  });

  // ---------------------------------------------------------------------------
  // Account management
  // ---------------------------------------------------------------------------

  /// Changes the user's password.
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Permanently deletes the user's account.
  Future<Result<void>> deleteAccount();
}
