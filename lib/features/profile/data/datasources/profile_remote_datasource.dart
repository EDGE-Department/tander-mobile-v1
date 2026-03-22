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
    AppLogger.debug(
      'Fetching my profile',
      operation: '$_tag.fetchMyProfile',
    );

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

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.userById(userId),
    );
  }

  /// Updates the authenticated user's profile via PUT /user/profile.
  Future<Response<Map<String, Object?>>> updateProfile({
    required UpdateProfileRequestDto request,
  }) {
    AppLogger.debug(
      'Updating profile',
      operation: '$_tag.updateProfile',
    );

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
      'file': await MultipartFile.fromFile(filePath),
    });

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.uploadProfilePhoto,
      data: formData,
    );
  }

  /// Uploads additional photos via POST /user/upload-additional-photos (multipart).
  Future<void> uploadAdditionalPhotos({
    required List<String> filePaths,
  }) async {
    AppLogger.debug(
      'Uploading additional photos',
      operation: '$_tag.uploadAdditionalPhotos',
      context: {'count': filePaths.length},
    );

    final multipartFiles = await Future.wait(
      filePaths.map(MultipartFile.fromFile),
    );

    final formData = FormData.fromMap(<String, Object>{
      'files': multipartFiles,
    });

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.uploadAdditionalPhotos,
      data: formData,
    );
  }

  /// Deletes a photo via DELETE /user/delete-photo?photoUrl={url}.
  Future<void> deletePhoto({required String photoUrl}) async {
    AppLogger.debug(
      'Deleting photo',
      operation: '$_tag.deletePhoto',
    );

    await _dioClient.delete<Map<String, Object?>>(
      ApiEndpoints.deletePhoto(photoUrl),
    );
  }

  /// Reorders photos via PUT /user/reorder-photos.
  Future<void> reorderPhotos({required List<String> photoUrls}) async {
    AppLogger.debug(
      'Reordering photos',
      operation: '$_tag.reorderPhotos',
      context: {'count': photoUrls.length},
    );

    await _dioClient.put<Map<String, Object?>>(
      ApiEndpoints.reorderPhotos,
      data: photoUrls,
    );
  }

  // ---------------------------------------------------------------------------
  // Notification settings
  // ---------------------------------------------------------------------------

  /// Fetches notification settings via GET /settings/notifications.
  Future<Response<Map<String, Object?>>> fetchNotificationSettings() {
    AppLogger.debug(
      'Fetching notification settings',
      operation: '$_tag.fetchNotificationSettings',
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.notificationSettings,
    );
  }

  /// Updates notification settings via PUT /settings/notifications.
  Future<void> updateNotificationSettings({
    required NotificationSettingsDto settings,
  }) async {
    AppLogger.debug(
      'Updating notification settings',
      operation: '$_tag.updateNotificationSettings',
    );

    await _dioClient.put<Map<String, Object?>>(
      ApiEndpoints.notificationSettings,
      data: settings.toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Privacy settings
  // ---------------------------------------------------------------------------

  /// Fetches privacy settings via GET /settings/privacy.
  Future<Response<Map<String, Object?>>> fetchPrivacySettings() {
    AppLogger.debug(
      'Fetching privacy settings',
      operation: '$_tag.fetchPrivacySettings',
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.privacySettings,
    );
  }

  /// Updates privacy settings via PUT /settings/privacy.
  Future<void> updatePrivacySettings({
    required PrivacySettingsDto settings,
  }) async {
    AppLogger.debug(
      'Updating privacy settings',
      operation: '$_tag.updatePrivacySettings',
    );

    await _dioClient.put<Map<String, Object?>>(
      ApiEndpoints.privacySettings,
      data: settings.toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Security settings
  // ---------------------------------------------------------------------------

  /// Fetches security settings via GET /settings/security.
  Future<Response<Map<String, Object?>>> fetchSecuritySettings() {
    AppLogger.debug(
      'Fetching security settings',
      operation: '$_tag.fetchSecuritySettings',
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.securitySettings,
    );
  }

  /// Updates security settings via PUT /settings/security.
  Future<void> updateSecuritySettings({
    required SecuritySettingsDto settings,
  }) async {
    AppLogger.debug(
      'Updating security settings',
      operation: '$_tag.updateSecuritySettings',
    );

    await _dioClient.put<Map<String, Object?>>(
      ApiEndpoints.securitySettings,
      data: settings.toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Discovery settings
  // ---------------------------------------------------------------------------

  /// Fetches discovery settings via GET /settings/discovery.
  Future<Response<Map<String, Object?>>> fetchDiscoverySettings() {
    AppLogger.debug(
      'Fetching discovery settings',
      operation: '$_tag.fetchDiscoverySettings',
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.discoverySettings,
    );
  }

  /// Updates discovery settings via PUT /settings/discovery.
  Future<void> updateDiscoverySettings({
    required DiscoverySettingsDto settings,
  }) async {
    AppLogger.debug(
      'Updating discovery settings',
      operation: '$_tag.updateDiscoverySettings',
    );

    await _dioClient.put<Map<String, Object?>>(
      ApiEndpoints.discoverySettings,
      data: settings.toJson(),
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
    AppLogger.debug(
      'Changing password',
      operation: '$_tag.changePassword',
    );

    await _dioClient.put<Map<String, Object?>>(
      ApiEndpoints.changePassword,
      data: ChangePasswordRequestDto(
        currentPassword: oldPassword,
        newPassword: newPassword,
      ).toJson(),
    );
  }

  /// Deletes the user's account via DELETE /user/delete-account.
  Future<void> deleteAccount() async {
    AppLogger.debug(
      'Deleting account',
      operation: '$_tag.deleteAccount',
    );

    await _dioClient.delete<Map<String, Object?>>(ApiEndpoints.deleteAccount);
  }
}
