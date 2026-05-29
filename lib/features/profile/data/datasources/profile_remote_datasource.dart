import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// All profile-related API calls, delegating HTTP to [DioClient].
///
/// Methods return raw [Response] objects or `void` so the repository layer
/// can map DTOs to domain models and wrap errors in [Result].
final class ProfileRemoteDatasource {
  const ProfileRemoteDatasource({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  static const String _tag = 'ProfileRemoteDatasource';

  // ---------------------------------------------------------------------------
  // Profile CRUD
  // ---------------------------------------------------------------------------

  /// Fetches the authenticated user's profile from GET /user/me.
  Future<Response<Map<String, Object?>>> fetchMyProfile() {
    AppLogger.debug('Fetching my profile', operation: '$_tag.fetchMyProfile');

    return _dioClient.get<Map<String, Object?>>(ApiEndpoints.userMe);
  }

  /// Fetches another user's profile by [userId] from GET /user/{userId}.
  Future<Response<Map<String, Object?>>> fetchUserProfile({
    required int userId,
  }) {
    AppLogger.debug(
      'Fetching user profile',
      operation: '$_tag.fetchUserProfile',
      context: {'userId': userId},
    );

    return _dioClient.get<Map<String, Object?>>(ApiEndpoints.userById(userId));
  }

  /// Updates the authenticated user's profile via PUT /user/profile.
  Future<Response<Map<String, Object?>>> updateProfile({
    required UpdateProfileRequestDto request,
  }) {
    AppLogger.debug('Updating profile', operation: '$_tag.updateProfile');

    return _dioClient.put<Map<String, Object?>>(
      ApiEndpoints.updateProfile,
      data: request.toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Photo management
  // ---------------------------------------------------------------------------

  /// Uploads a profile photo via POST /user/upload-profile-photo (multipart).
  Future<void> uploadProfilePhoto({required String filePath}) async {
    AppLogger.debug(
      'Uploading profile photo',
      operation: '$_tag.uploadProfilePhoto',
    );

    final formData = FormData.fromMap(<String, Object>{
      'profilePhoto': await MultipartFile.fromFile(
        filePath,
        filename: 'profile-photo.jpg',
      ),
    });

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.uploadProfilePhoto,
      data: formData,
    );
  }

  /// Uploads additional photos via POST /user/upload-additional-photos (multipart).
  Future<void> uploadAdditionalPhotos({required List<String> filePaths}) async {
    AppLogger.debug(
      'Uploading additional photos',
      operation: '$_tag.uploadAdditionalPhotos',
      context: {'count': filePaths.length},
    );

    final multipartFiles = await Future.wait(
      filePaths.map(MultipartFile.fromFile),
    );

    final formData = FormData.fromMap(<String, Object>{
      'additionalPhotos': multipartFiles,
    });

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.uploadAdditionalPhotos,
      data: formData,
    );
  }

  /// Deletes the main profile photo via DELETE /user/delete-profile-photo.
  Future<void> deleteProfilePhoto() async {
    AppLogger.debug(
      'Deleting profile photo',
      operation: '$_tag.deleteProfilePhoto',
    );
    await _dioClient.delete<Map<String, Object?>>(
      ApiEndpoints.deleteProfilePhoto,
    );
  }

  /// Deletes an additional photo by index via DELETE /user/delete-photo?photoIndex=N.
  Future<void> deleteAdditionalPhoto({required int photoIndex}) async {
    AppLogger.debug(
      'Deleting additional photo at index $photoIndex',
      operation: '$_tag.deleteAdditionalPhoto',
    );
    await _dioClient.delete<Map<String, Object?>>(
      ApiEndpoints.deletePhotoByIndex(photoIndex),
    );
  }

  /// Reorders photos via PUT /user/reorder-photos.
  Future<void> reorderPhotos({required List<String> photoUrls}) async {
    AppLogger.debug(
      'Reordering photos',
      operation: '$_tag.reorderPhotos',
      context: {'count': photoUrls.length},
    );

    await _dioClient.patch<Map<String, Object?>>(
      ApiEndpoints.reorderPhotos,
      data: <String, Object>{'photoUrls': photoUrls},
    );
  }

  // ---------------------------------------------------------------------------
  // Settings (Unified)
  // ---------------------------------------------------------------------------

  Future<Response<Map<String, Object?>>> fetchUserSettings() {
    AppLogger.debug(
      'Fetching user settings',
      operation: '$_tag.fetchUserSettings',
    );
    return _dioClient.get<Map<String, Object?>>(ApiEndpoints.userSettings);
  }

  Future<void> updateUserSettings({
    required UpdateSettingsRequestDto request,
  }) async {
    AppLogger.debug(
      'Updating user settings',
      operation: '$_tag.updateUserSettings',
    );
    await _dioClient.patch<Map<String, Object?>>(
      ApiEndpoints.userSettings,
      data: request.toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Account management
  // ---------------------------------------------------------------------------

  /// Changes the user's password via PUT /user/change-password.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    AppLogger.debug('Changing password', operation: '$_tag.changePassword');

    await _dioClient.patch<Map<String, Object?>>(
      ApiEndpoints.changePassword,
      data: ChangePasswordRequestDto(
        currentPassword: oldPassword,
        newPassword: newPassword,
      ).toJson(),
    );
  }

  /// Requests account deletion via POST /privacy/account-deletion.
  ///
  /// Schedules a deletion with a 30-day grace window (server responds 202
  /// with the created [DeletionResponse]).
  Future<Response<Map<String, Object?>>> requestAccountDeletion({
    String? reason,
  }) {
    AppLogger.debug(
      'Requesting account deletion',
      operation: '$_tag.requestAccountDeletion',
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.requestAccountDeletion,
      data: <String, Object?>{
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  /// Cancels an in-grace account deletion via
  /// POST /privacy/account-deletion/cancel.
  Future<Response<Map<String, Object?>>> cancelAccountDeletion() {
    AppLogger.debug(
      'Cancelling account deletion',
      operation: '$_tag.cancelAccountDeletion',
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.cancelAccountDeletion,
    );
  }

  /// Reads the active deletion request via GET /privacy/account-deletion.
  ///
  /// The server returns 204 No Content when there is no active request.
  Future<Response<Map<String, Object?>>> fetchAccountDeletionStatus() {
    AppLogger.debug(
      'Fetching account deletion status',
      operation: '$_tag.fetchAccountDeletionStatus',
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.accountDeletionStatus,
    );
  }

  /// Requests a data export via POST /privacy/export.
  ///
  /// The server responds 202 and prepares the export asynchronously (the
  /// user is notified when it's ready).
  Future<Response<Map<String, Object?>>> requestDataExport() {
    AppLogger.debug(
      'Requesting data export',
      operation: '$_tag.requestDataExport',
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.requestDataExport,
    );
  }
}
