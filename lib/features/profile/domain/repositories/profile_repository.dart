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
  // Notification settings
  // ---------------------------------------------------------------------------

  /// Fetches the user's notification preferences.
  Future<Result<NotificationSettings>> fetchNotificationSettings();

  /// Updates the user's notification preferences.
  Future<Result<void>> updateNotificationSettings({
    required NotificationSettingsDto settings,
  });

  // ---------------------------------------------------------------------------
  // Privacy settings
  // ---------------------------------------------------------------------------

  /// Fetches the user's privacy settings.
  Future<Result<PrivacySettings>> fetchPrivacySettings();

  /// Updates the user's privacy settings.
  Future<Result<void>> updatePrivacySettings({
    required PrivacySettingsDto settings,
  });

  // ---------------------------------------------------------------------------
  // Security settings
  // ---------------------------------------------------------------------------

  /// Fetches the user's security settings (2FA, active sessions).
  Future<Result<SecuritySettings>> fetchSecuritySettings();

  /// Updates the user's security settings.
  Future<Result<void>> updateSecuritySettings({
    required SecuritySettingsDto settings,
  });

  // ---------------------------------------------------------------------------
  // Discovery settings
  // ---------------------------------------------------------------------------

  /// Fetches the user's discovery preferences.
  Future<Result<DiscoverySettings>> fetchDiscoverySettings();

  /// Updates the user's discovery preferences.
  Future<Result<void>> updateDiscoverySettings({
    required DiscoverySettingsDto settings,
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
