import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/contracts/auth_contracts.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/mappers/auth_mapper.dart';
import 'package:tander_flutter_v3/core/realtime/stomp_client_manager.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';

/// Coordinates [AuthRemoteDatasource], [AuthLocalDatasource], and
/// [SessionManager] to fulfil the [AuthRepository] contract.
///
/// Every public method catches all exceptions and wraps them in
/// [Failure] so callers never see raw throws.
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required AuthLocalDatasource localDatasource,
    required SessionManager sessionManager,
    required SecureStorage secureStorage,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource,
        _sessionManager = sessionManager,
        _secureStorage = secureStorage;

  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;
  final SessionManager _sessionManager;
  final SecureStorage _secureStorage;

  static const String _tag = 'AuthRepositoryImpl';

  // ---------------------------------------------------------------------------
  // Sign in
  // ---------------------------------------------------------------------------

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) {
    return _runSafe('signIn', () async {
      // 1. Call login endpoint — same as web: POST /auth/login
      final loginResponse = await _remoteDatasource.signIn(
        email: email,
        password: password,
      );

      // 2. Extract Jwt-Token header — same as web
      final accessToken = _extractAccessToken(loginResponse.headers);

      // 3. Extract refreshToken from response body — parse manually
      //    like the web does (no strict DTO, backend sends nullable fields)
      final body = loginResponse.data;
      final data = body?['data'];
      final refreshToken = data is Map<String, Object?>
          ? data['refreshToken'] as String?
          : null;

      if (refreshToken == null || refreshToken.isEmpty) {
        throw const FormatException('Missing refreshToken in login response');
      }

      // 4. Save tokens — same as web: setAccessToken + setRefreshToken
      await _localDatasource.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _sessionManager.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // 5. Fetch /user/me to get the real userId and profile — same as web
      final session = await _fetchAndMapSession();
      _sessionManager.setSession(session);
      _connectStomp(accessToken);

      return session;
    });
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void>> signOut() {
    return _runSafe('signOut', () async {
      StompClientManager.instance.disconnect();
      await _sessionManager.clearSession();
      await _localDatasource.clearTokens();
      await _localDatasource.clearCachedUser();
      AppLogger.info('Sign-out complete', operation: _tag);
    });
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------

  @override
  Future<Result<AuthSession>> register({
    String? email,
    String? phone,
    required String password,
    required String auditId,
  }) {
    return _runSafe('register', () async {
      final requestDto = RegisterRequestDto(
        email: email,
        phone: phone,
        password: password,
        auditId: auditId,
        consentTerms: true,
        consentDataPrivacy: true,
      );

      final registerResponse = await _remoteDatasource.register(
        request: requestDto,
      );

      final responseBody = registerResponse.data;
      if (responseBody == null) {
        throw const FormatException(
          'Empty response body from register endpoint',
        );
      }

      // Backend register returns 201 without tokens — user must verify
      // email before logging in. Extract what we can from the response.
      final bodyData = responseBody['data'];
      final username = bodyData is Map<String, Object?>
          ? bodyData['username'] as String? ?? ''
          : '';
      final registrationPhase = bodyData is Map<String, Object?>
          ? bodyData['registrationPhase'] as String? ?? 'email_pending'
          : 'email_pending';

      // Access token is optional — backend may not issue one at registration.
      final rawJwtHeader = registerResponse.headers.value('jwt-token');
      final hasToken = rawJwtHeader != null && rawJwtHeader.isNotEmpty;

      if (hasToken) {
        final accessToken = _extractAccessToken(registerResponse.headers);
        final refreshToken = bodyData is Map<String, Object?>
            ? (bodyData['refreshToken'] is String
                ? bodyData['refreshToken']! as String
                : '')
            : '';

        if (refreshToken.isNotEmpty) {
          await _localDatasource.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          await _sessionManager.setTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        }
      }

      final session = AuthSession(
        userId: 0,
        email: email,
        username: username,
        registrationPhase:
            RegistrationPhase.fromBackendString(registrationPhase),
        isEmailVerified: false,
        isIdVerified: true,
      );

      _sessionManager.setSession(session);

      AppLogger.info(
        'Registration successful for user $username',
        operation: _tag,
      );

      return session;
    });
  }

  // ---------------------------------------------------------------------------
  // Get current user
  // ---------------------------------------------------------------------------

  @override
  Future<Result<AuthSession>> getCurrentUser() {
    return _runSafe('getCurrentUser', () async {
      final session = await _fetchAndMapSession();
      _sessionManager.setSession(session);
      return session;
    });
  }

  // ---------------------------------------------------------------------------
  // Bootstrap session
  // ---------------------------------------------------------------------------

  @override
  Future<Result<bool>> bootstrapSession() {
    return _runSafe('bootstrapSession', () async {
      final isRestored = await _sessionManager.bootstrapSession();

      if (isRestored) {
        final accessToken = _sessionManager.accessToken;
        if (accessToken != null) {
          _connectStomp(accessToken);
        }
      }

      return isRestored;
    });
  }

  // ---------------------------------------------------------------------------
  // Password reset flow
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void>> requestPasswordReset({String? email, String? phone}) {
    return _runSafe('requestPasswordReset', () async {
      await _remoteDatasource.requestPasswordReset(
        email: email,
        phone: phone,
      );
    });
  }

  @override
  Future<Result<String>> verifyResetOtp({
    String? email,
    String? phone,
    required String otp,
  }) {
    return _runSafe('verifyResetOtp', () async {
      final response = await _remoteDatasource.verifyResetOtp(
        email: email,
        phone: phone,
        otp: otp,
      );

      final body = response.data;
      if (body == null) {
        throw const FormatException('Empty response from verify-reset-otp');
      }

      final data = body['data'];
      if (data is Map<String, Object?>) {
        final resetToken = data['resetToken'];
        if (resetToken is String && resetToken.isNotEmpty) {
          return resetToken;
        }
      }

      throw const FormatException('Missing resetToken in verify-reset-otp response');
    });
  }

  @override
  Future<Result<void>> resetPassword({
    String? email,
    String? phone,
    required String resetToken,
    required String newPassword,
  }) {
    return _runSafe('resetPassword', () async {
      await _remoteDatasource.resetPassword(
        email: email,
        phone: phone,
        resetToken: resetToken,
        newPassword: newPassword,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Email verification
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void>> resendEmailVerification({required String email}) {
    return _runSafe('resendEmailVerification', () async {
      await _remoteDatasource.resendEmailVerification(email: email);
    });
  }

  // ---------------------------------------------------------------------------
  // Registration OTP
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void>> sendRegistrationOtp({String? email, String? phone}) {
    return _runSafe('sendRegistrationOtp', () async {
      await _remoteDatasource.sendRegistrationOtp(
        email: email,
        phone: phone,
      );
    });
  }

  @override
  Future<Result<bool>> verifyRegistrationOtp({
    String? email,
    String? phone,
    required String otp,
  }) {
    return _runSafe('verifyRegistrationOtp', () async {
      return _remoteDatasource.verifyRegistrationOtp(
        email: email,
        phone: phone,
        otp: otp,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Availability checks
  // ---------------------------------------------------------------------------

  @override
  Future<Result<bool>> checkEmailAvailability({required String email}) {
    return _runSafe('checkEmailAvailability', () async {
      return _remoteDatasource.checkEmailAvailability(email: email);
    });
  }

  @override
  Future<Result<bool>> checkUsernameAvailability({required String username}) {
    return _runSafe('checkUsernameAvailability', () async {
      return _remoteDatasource.checkUsernameAvailability(username: username);
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

  /// Extracts the access token from the `Jwt-Token` response header.
  ///
  /// CRITICAL: the header value arrives as `"Bearer {token}"` -- the prefix
  /// must be stripped before storage.
  String _extractAccessToken(Headers headers) {
    final rawJwtHeader = headers.value('jwt-token');

    if (rawJwtHeader == null || rawJwtHeader.isEmpty) {
      throw const FormatException(
        'Missing Jwt-Token header in authentication response',
      );
    }

    final accessToken = rawJwtHeader.startsWith('Bearer ')
        ? rawJwtHeader.substring(7)
        : rawJwtHeader;

    if (accessToken.isEmpty) {
      throw const FormatException(
        'Empty access token after stripping Bearer prefix',
      );
    }

    return accessToken;
  }

  // ---------------------------------------------------------------------------
  // Phone availability
  // ---------------------------------------------------------------------------

  @override
  Future<Result<bool>> checkPhoneAvailability({required String phone}) {
    return _runSafe('checkPhoneAvailability', () async {
      return _remoteDatasource.checkPhoneAvailability(phone: phone);
    });
  }

  // ---------------------------------------------------------------------------
  // Minimum age
  // ---------------------------------------------------------------------------

  @override
  Future<Result<int>> getMinimumAge() {
    return _runSafe('getMinimumAge', () async {
      return _remoteDatasource.getMinimumAge();
    });
  }

  // ---------------------------------------------------------------------------
  // ID pre-registration verification
  // ---------------------------------------------------------------------------

  @override
  Future<Result<String>> verifyIdPreRegister({
    required String idPhotoFrontPath,
    String? selfiePath,
    Map<String, dynamic>? livenessMetadata,
    Map<String, dynamic>? frontendOcrData,
    String? deviceFingerprint,
  }) {
    return _runSafe('verifyIdPreRegister', () async {
      Response<Map<String, Object?>> response;
      try {
        response = await _remoteDatasource.verifyIdPreRegister(
          idPhotoFrontPath: idPhotoFrontPath,
          selfiePath: selfiePath,
          livenessMetadata: livenessMetadata,
          frontendOcrData: frontendOcrData,
          deviceFingerprint: deviceFingerprint,
        );
      } on DioException catch (e) {
        // Handle HTTP error responses (4xx, 5xx)
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final code = responseData['code'] as String? ?? '';
          final message = responseData['message'] as String? ?? 'Verification failed';
          final emailHint = responseData['emailHint'] as String?;

          // Check for duplicate ID errors
          if (code == 'DUPLICATE_ID_DETECTED' ||
              code == 'IDENTIFIER_IN_USE' ||
              code == 'ID_BLOCKED' ||
              message.toLowerCase().contains('already been used') ||
              message.toLowerCase().contains('already registered')) {
            // Include email hint in the exception message if available
            final hintPart = emailHint != null ? '|HINT:$emailHint' : '';
            throw FormatException('IDENTIFIER_IN_USE$hintPart: $message');
          }

          throw FormatException(message);
        }
        rethrow;
      }

      final body = response.data;
      if (body == null) {
        throw const FormatException(
          'Empty response body from verify-id-pre-register',
        );
      }

      // Check for error response from backend
      final success = body['success'];
      if (success == false) {
        final code = body['code'] as String? ?? '';
        final message = body['message'] as String? ?? 'Verification failed';

        // Check for duplicate ID / identifier already in use
        if (code == 'IDENTIFIER_IN_USE' ||
            code == 'DUPLICATE_ID' ||
            message.toLowerCase().contains('already') ||
            message.toLowerCase().contains('duplicate')) {
          throw FormatException('IDENTIFIER_IN_USE: $message');
        }

        // Throw with the error message
        throw FormatException(message);
      }

      // Extract auditId from response
      final data = body['data'];
      String? auditId;
      if (data is Map<String, Object?>) {
        auditId = data['auditId'] as String?;
      }

      if (auditId == null || auditId.isEmpty) {
        // Also check for error code at top level (backend inconsistency)
        final code = body['code'] as String? ?? '';
        if (code == 'IDENTIFIER_IN_USE') {
          throw const FormatException('IDENTIFIER_IN_USE: This ID has already been registered');
        }
        throw const FormatException(
          'Missing auditId in verify-id-pre-register response',
        );
      }

      // Store auditId in secure storage for later use during registration
      await _secureStorage.saveAuditId(auditId);

      AppLogger.info(
        'ID pre-registration verified, auditId stored',
        operation: _tag,
      );

      return auditId;
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Calls GET /user/me and maps the response to an [AuthSession].
  Future<AuthSession> _fetchAndMapSession() async {
    final userMeResponse = await _remoteDatasource.fetchUserMe();
    final userMeJson = userMeResponse.data;

    if (userMeJson == null) {
      throw const FormatException(
        'Empty response body from /user/me endpoint',
      );
    }

    return AuthMapper.mapToAuthSession(userMeJson);
  }

  /// Connects the STOMP WebSocket client with the given [accessToken].
  void _connectStomp(String accessToken) {
    StompClientManager.instance.connect(
      accessToken: accessToken,
      secureStorage: _secureStorage,
    );
  }
}
