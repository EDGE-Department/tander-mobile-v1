import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

/// Wraps [FlutterSecureStorage] for sensitive auth credentials.
///
/// The access token stored here is a **cold-start backup only**.
/// At runtime the canonical access token lives in-memory inside
/// `SessionManager`; this copy is read once during bootstrap and
/// then kept in sync as a fallback for app restarts.
final class SecureStorage {
  const SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _auditIdKey = 'audit_id';
  static const String _pendingEmailKey = 'pending_reg_email';
  static const String _pendingPhoneKey = 'pending_reg_phone';
  static const String _pendingPasswordKey = 'pending_reg_password';
  static const String _pendingAuditIdKey = 'pending_reg_audit_id';

  // ---------------------------------------------------------------------------
  // Access token (cold-start backup)
  // ---------------------------------------------------------------------------

  Future<Result<String?>> readAccessToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      return Success(token);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to read access token: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to save access token: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> deleteAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to delete access token: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh token
  // ---------------------------------------------------------------------------

  Future<Result<String?>> readRefreshToken() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      return Success(token);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to read refresh token: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to save refresh token: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to delete refresh token: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Audit ID (pre-registration ID verification)
  // ---------------------------------------------------------------------------

  Future<Result<String?>> readAuditId() async {
    try {
      final auditId = await _storage.read(key: _auditIdKey);
      return Success(auditId);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to read auditId: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> saveAuditId(String auditId) async {
    try {
      await _storage.write(key: _auditIdKey, value: auditId);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to save auditId: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<Result<void>> deleteAuditId() async {
    try {
      await _storage.delete(key: _auditIdKey);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to delete auditId: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pending registration (credentials stored until OTP verified)
  // ---------------------------------------------------------------------------

  Future<void> savePendingRegistration({
    String? email,
    String? phone,
    required String password,
    required String auditId,
  }) async {
    if (email != null) await _storage.write(key: _pendingEmailKey, value: email);
    if (phone != null) await _storage.write(key: _pendingPhoneKey, value: phone);
    await _storage.write(key: _pendingPasswordKey, value: password);
    await _storage.write(key: _pendingAuditIdKey, value: auditId);
  }

  Future<({String? email, String? phone, String? password, String? auditId})>
      readPendingRegistration() async {
    return (
      email: await _storage.read(key: _pendingEmailKey),
      phone: await _storage.read(key: _pendingPhoneKey),
      password: await _storage.read(key: _pendingPasswordKey),
      auditId: await _storage.read(key: _pendingAuditIdKey),
    );
  }

  Future<void> clearPendingRegistration() async {
    await _storage.delete(key: _pendingEmailKey);
    await _storage.delete(key: _pendingPhoneKey);
    await _storage.delete(key: _pendingPasswordKey);
    await _storage.delete(key: _pendingAuditIdKey);
  }

  // ---------------------------------------------------------------------------
  // Bulk operations
  // ---------------------------------------------------------------------------

  Future<Result<void>> clearAllSecureData() async {
    try {
      await _storage.deleteAll();
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        StorageException(
          message: 'Failed to clear all secure storage: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
