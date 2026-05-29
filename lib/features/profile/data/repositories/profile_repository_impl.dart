import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/mappers/profile_mapper.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:tander_flutter_v3/features/profile/domain/models/account_deletion_status.dart';
import 'package:tander_flutter_v3/features/profile/domain/repositories/profile_repository.dart';

/// Coordinates [ProfileRemoteDatasource] and [ProfileMapper] to fulfil
/// the [ProfileRepository] contract.
///
/// Every public method catches all exceptions and wraps them in
/// [Failure] so callers never see raw throws.
final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final ProfileRemoteDatasource _remoteDatasource;

  static const String _tag = 'ProfileRepositoryImpl';

  // ---------------------------------------------------------------------------
  // Profile CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<Result<UserProfile>> fetchMyProfile() {
    return _runSafe('fetchMyProfile', () async {
      final response = await _remoteDatasource.fetchMyProfile();
      return _mapProfileResponse(response.data);
    });
  }

  @override
  Future<Result<UserProfile>> fetchUserProfile({required int userId}) {
    return _runSafe('fetchUserProfile', () async {
      final response = await _remoteDatasource.fetchUserProfile(userId: userId);
      return _mapProfileResponse(response.data);
    });
  }

  @override
  Future<Result<UserProfile>> updateProfile({
    required UpdateProfileRequestDto request,
  }) {
    return _runSafe('updateProfile', () async {
      // Send the update
      await _remoteDatasource.updateProfile(request: request);
      // Refetch profile — the PUT response has inconsistent field formats
      // (additionalPhotos as String vs List), so use the GET endpoint
      // which always returns the correct shape.
      final refreshed = await _remoteDatasource.fetchMyProfile();
      return _mapProfileResponse(refreshed.data);
    });
  }

  // ---------------------------------------------------------------------------
  // Photo management
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void>> uploadProfilePhoto({required String filePath}) {
    return _runSafe('uploadProfilePhoto', () async {
      await _remoteDatasource.uploadProfilePhoto(filePath: filePath);
    });
  }

  @override
  Future<Result<void>> uploadAdditionalPhotos({
    required List<String> filePaths,
  }) {
    return _runSafe('uploadAdditionalPhotos', () async {
      await _remoteDatasource.uploadAdditionalPhotos(filePaths: filePaths);
    });
  }

  @override
  Future<Result<void>> deletePhoto({required int galleryIndex}) {
    return _runSafe('deletePhoto', () async {
      if (galleryIndex == 0) {
        await _remoteDatasource.deleteProfilePhoto();
      } else {
        // Gallery index 1+ maps to additionalPhotos index 0+
        await _remoteDatasource.deleteAdditionalPhoto(
          photoIndex: galleryIndex - 1,
        );
      }
    });
  }

  @override
  Future<Result<void>> reorderPhotos({required List<String> photoUrls}) {
    return _runSafe('reorderPhotos', () async {
      await _remoteDatasource.reorderPhotos(photoUrls: photoUrls);
    });
  }

  // ---------------------------------------------------------------------------
  // Settings (Unified)
  // ---------------------------------------------------------------------------

  @override
  Future<Result<UserSettings>> fetchUserSettings() {
    return _runSafe('fetchUserSettings', () async {
      final response = await _remoteDatasource.fetchUserSettings();
      final body = _requireResponseBody(response.data, 'user settings');
      final unwrapped = _unwrapResponse(body);
      return ProfileMapper.mapUserSettingsDto(
        UserSettingsDto.fromJson(unwrapped),
      );
    });
  }

  @override
  Future<Result<void>> updateUserSettings({
    required UpdateSettingsRequestDto request,
  }) {
    return _runSafe('updateUserSettings', () async {
      await _remoteDatasource.updateUserSettings(request: request);
    });
  }

  // ---------------------------------------------------------------------------
  // Account management
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _runSafe('changePassword', () async {
      await _remoteDatasource.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    });
  }

  @override
  Future<Result<AccountDeletionStatus>> requestAccountDeletion({
    String? reason,
  }) {
    return _runSafe('requestAccountDeletion', () async {
      final response = await _remoteDatasource.requestAccountDeletion(
        reason: reason,
      );
      return AccountDeletionStatus.fromJson(
        response.data ?? const <String, Object?>{},
      );
    });
  }

  @override
  Future<Result<AccountDeletionStatus>> cancelAccountDeletion() {
    return _runSafe('cancelAccountDeletion', () async {
      final response = await _remoteDatasource.cancelAccountDeletion();
      return AccountDeletionStatus.fromJson(
        response.data ?? const <String, Object?>{},
      );
    });
  }

  @override
  Future<Result<AccountDeletionStatus?>> fetchAccountDeletionStatus() {
    return _runSafe('fetchAccountDeletionStatus', () async {
      final response = await _remoteDatasource.fetchAccountDeletionStatus();
      // 204 No Content → no active deletion request.
      if (response.statusCode == 204 || response.data == null) return null;
      return AccountDeletionStatus.fromJson(response.data!);
    });
  }

  @override
  Future<Result<void>> requestDataExport() {
    return _runSafe('requestDataExport', () async {
      await _remoteDatasource.requestDataExport();
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Wraps [action] in a uniform try/catch that maps all exceptions to
  /// [Result.Failure], forwarding [AppException] subclasses directly and
  /// wrapping anything else in [UnknownException].
  Future<Result<TValue>> _runSafe<TValue>(
    String operationName,
    Future<TValue> Function() action,
  ) async {
    try {
      final value = await action();
      return Success(value);
    } on AppException catch (exception) {
      return Failure(exception);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        '$operationName failed',
        operation: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      return Failure(
        UnknownException(
          message: '$operationName failed: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Maps the raw response body to a [UserProfile] via the DTO layer.
  ///
  /// Throws [FormatException] when the body is null.
  UserProfile _mapProfileResponse(Map<String, Object?>? responseBody) {
    final body = _requireResponseBody(responseBody, 'profile');
    final unwrapped = _unwrapResponse(body);
    final dto = UserProfileDto.fromJson(unwrapped);
    return ProfileMapper.mapUserProfileDto(dto);
  }

  /// Returns [body] if non-null, otherwise throws a [FormatException]
  /// with a descriptive error identifying the [endpointLabel].
  Map<String, Object?> _requireResponseBody(
    Map<String, Object?>? body,
    String endpointLabel,
  ) {
    if (body == null) {
      throw FormatException('Empty response body from $endpointLabel endpoint');
    }
    return body;
  }

  /// Unwraps the backend's standard `{success, data}` wrapper.
  /// If the response is already unwrapped (no `data` key), returns as-is.
  Map<String, Object?> _unwrapResponse(Map<String, Object?> body) {
    if (body.containsKey('data') && body['data'] is Map<String, Object?>) {
      return body['data'] as Map<String, Object?>;
    }
    return body;
  }
}
