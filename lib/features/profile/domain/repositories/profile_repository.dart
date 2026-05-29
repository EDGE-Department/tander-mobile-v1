import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/profile/domain/models/account_deletion_status.dart';

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

  /// Requests account deletion. The account enters a 30-day grace window
  /// during which it stays usable and the request can be cancelled.
  Future<Result<AccountDeletionStatus>> requestAccountDeletion({
    String? reason,
  });

  /// Cancels an in-grace account-deletion request.
  Future<Result<AccountDeletionStatus>> cancelAccountDeletion();

  /// Returns the active deletion request, or `null` if none is pending.
  Future<Result<AccountDeletionStatus?>> fetchAccountDeletionStatus();

  /// Requests a data export. The server prepares it asynchronously and
  /// notifies the user when it's ready.
  Future<Result<void>> requestDataExport();
}
