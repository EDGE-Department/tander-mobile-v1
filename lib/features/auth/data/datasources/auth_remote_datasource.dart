import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/contracts/auth_contracts.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// All auth-related API calls, delegating HTTP to [DioClient].
///
/// Every method that produces a meaningful response body returns the raw
/// [Response] so the caller can inspect headers (e.g. `Jwt-Token` on login)
/// alongside the body.
///
/// Fire-and-forget endpoints (password reset request, OTP sends, etc.) return
/// `void` — they succeed or throw.
final class AuthRemoteDatasource {
  const AuthRemoteDatasource({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Signs in with email/username + password.
  ///
  /// **CRITICAL**: Returns the raw [Response] so the caller can read the
  /// `Jwt-Token` header for access-token extraction.
  Future<Response<Map<String, Object?>>> signIn({
    required String email,
    required String password,
  }) {
    AppLogger.debug(
      'Signing in',
      operation: 'AuthRemoteDatasource.signIn',
      context: {'email': email},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.login,
      data: LoginRequestDto(identifier: email, password: password).toJson(),
    );
  }

  /// Registers a new user account.
  Future<Response<Map<String, Object?>>> register({
    required RegisterRequestDto request,
  }) {
    AppLogger.debug(
      'Registering new user',
      operation: 'AuthRemoteDatasource.register',
      context: {
        if (request.email != null) 'email': request.email!,
        if (request.phone != null) 'phone': request.phone!,
      },
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.register,
      data: request.toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Token refresh
  // ---------------------------------------------------------------------------

  /// Exchanges a refresh token for a new token pair.
  ///
  /// The new access token arrives in the `Jwt-Token` response header;
  /// the new refresh token is in the response body.
  Future<Response<Map<String, Object?>>> refreshToken({
    required String refreshToken,
  }) {
    AppLogger.debug(
      'Refreshing token',
      operation: 'AuthRemoteDatasource.refreshToken',
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
  }

  // ---------------------------------------------------------------------------
  // Password reset flow
  // ---------------------------------------------------------------------------

  /// Requests a password-reset OTP to be sent to [email] or [phone].
  Future<void> requestPasswordReset({String? email, String? phone}) async {
    AppLogger.debug(
      'Requesting password reset',
      operation: 'AuthRemoteDatasource.requestPasswordReset',
      context: {'email': ?email, 'phone': ?phone},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.forgotPassword,
      data: ForgotPasswordRequestDto(email: email, phoneNumber: phone).toJson(),
    );
  }

  /// Verifies the password-reset OTP and returns the response containing
  /// the one-time reset token.
  Future<Response<Map<String, Object?>>> verifyResetOtp({
    String? email,
    String? phone,
    required String otp,
  }) {
    AppLogger.debug(
      'Verifying reset OTP',
      operation: 'AuthRemoteDatasource.verifyResetOtp',
      context: {'email': ?email, 'phone': ?phone},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.verifyResetOtp,
      data: VerifyResetOtpRequestDto(
        email: email,
        phoneNumber: phone,
        code: otp,
      ).toJson(),
    );
  }

  /// Resets the password using the one-time reset token from [verifyResetOtp].
  Future<void> resetPassword({
    String? email,
    String? phone,
    required String resetToken,
    required String newPassword,
  }) async {
    AppLogger.debug(
      'Resetting password',
      operation: 'AuthRemoteDatasource.resetPassword',
      context: {'email': ?email, 'phone': ?phone},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.resetPassword,
      data: ResetPasswordRequestDto(
        email: email,
        phoneNumber: phone,
        resetToken: resetToken,
        newPassword: newPassword,
      ).toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Email verification
  // ---------------------------------------------------------------------------

  /// Resends the email-verification link.
  Future<void> resendEmailVerification({required String email}) async {
    AppLogger.debug(
      'Resending email verification',
      operation: 'AuthRemoteDatasource.resendEmailVerification',
      context: {'email': email},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.resendVerification,
      data: ResendVerificationRequestDto(email: email).toJson(),
    );
  }

  // ---------------------------------------------------------------------------
  // Registration OTP (Twilio)
  // ---------------------------------------------------------------------------

  /// Sends a registration OTP to email (via Gmail SMTP) or phone (via Twilio SMS).
  Future<void> sendRegistrationOtp({String? email, String? phone}) async {
    AppLogger.debug(
      'Sending registration OTP',
      operation: 'AuthRemoteDatasource.sendRegistrationOtp',
      context: {'email': ?email, 'phone': ?phone},
    );

    if (phone != null && phone.isNotEmpty) {
      await _dioClient.post<Map<String, Object?>>(
        ApiEndpoints.sendOtp,
        data: {'phoneNumber': phone, 'channel': 'sms'},
      );
    } else {
      await _dioClient.post<Map<String, Object?>>(
        ApiEndpoints.sendEmailOtp,
        data: {'email': email},
      );
    }
  }

  /// Verifies the registration OTP for email or phone.
  Future<bool> verifyRegistrationOtp({
    String? email,
    String? phone,
    required String otp,
  }) async {
    AppLogger.debug(
      'Verifying registration OTP',
      operation: 'AuthRemoteDatasource.verifyRegistrationOtp',
      context: {'email': ?email, 'phone': ?phone},
    );

    if (phone != null && phone.isNotEmpty) {
      final response = await _dioClient.post<Map<String, Object?>>(
        ApiEndpoints.verifyOtp,
        data: {'phoneNumber': phone, 'code': otp},
      );
      final body = response.data;
      return body != null && body['valid'] == true;
    } else {
      final response = await _dioClient.post<Map<String, Object?>>(
        ApiEndpoints.verifyEmailOtp,
        data: {'email': email, 'code': otp},
      );
      final body = response.data;
      return body != null && body['valid'] == true;
    }
  }

  // ---------------------------------------------------------------------------
  // Availability checks
  // ---------------------------------------------------------------------------

  /// Returns `true` if the email is available for registration.
  Future<bool> checkEmailAvailability({required String email}) async {
    AppLogger.debug(
      'Checking email availability',
      operation: 'AuthRemoteDatasource.checkEmailAvailability',
    );

    final response = await _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.checkEmail,
      queryParameters: {'email': email},
    );

    return _parseAvailability(response.data);
  }

  /// Returns `true` if the username is available for registration.
  Future<bool> checkUsernameAvailability({required String username}) async {
    AppLogger.debug(
      'Checking username availability',
      operation: 'AuthRemoteDatasource.checkUsernameAvailability',
    );

    final response = await _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.checkUsername,
      queryParameters: {'username': username},
    );

    return _parseAvailability(response.data);
  }

  /// Returns `true` if the phone number is available for registration.
  Future<bool> checkPhoneAvailability({required String phone}) async {
    AppLogger.debug(
      'Checking phone availability',
      operation: 'AuthRemoteDatasource.checkPhoneAvailability',
    );

    final response = await _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.checkPhone,
      queryParameters: {'phoneNumber': phone},
    );

    return _parseAvailability(response.data);
  }

  /// Backend returns `{ data: { exists: bool, blocked: bool } }`.
  /// Available = not exists AND not blocked.
  bool _parseAvailability(Map<String, Object?>? body) {
    final data = body?['data'];
    if (data is Map<String, Object?>) {
      final exists = data['exists'];
      final blocked = data['blocked'];
      // Legitimately taken/blocked — a normal result, not drift. No warning.
      if (exists is bool && exists) return false;
      if (blocked is bool && blocked) return false;
      // At least one flag is a readable bool (and false) → legitimately
      // available. Normal result, no warning. (Behaviour preserved.)
      if (exists is bool || blocked is bool) return true;

      // Shape drift (arm 2): `data` is a Map but neither `exists` nor
      // `blocked` is a readable bool. Log, then preserve the original
      // available (`true`) behaviour for this in-Map path.
      //
      // NOTE: On unexpected shape we log but keep the original return value.
      // A backend response-shape drift surfaces in logs rather than silently
      // mis-parsing. See registration review (Theme B).
      AppLogger.warning(
        'Availability data missing exists/blocked flags — treating as available',
        operation: 'AuthRemoteDatasource._parseAvailability',
        context: {'data': '$data'},
      );
      return true;
    }

    // Shape drift (arm 1): `data` is missing or not a Map, so neither flag
    // could be read. This is the higher-stakes silent-failure case — a drift
    // here returns false ("taken") and would block all signups with no
    // diagnostic. Log it so the drift is diagnosable.
    //
    // NOTE: On unexpected shape we log + return false (treated as "taken"). A
    // backend response-shape drift will surface in logs rather than silently
    // blocking all signups. See registration review (Theme B).
    AppLogger.warning(
      'Unexpected availability response shape — treating as taken',
      operation: 'AuthRemoteDatasource._parseAvailability',
      context: {'body': '$body'},
    );
    return false;
  }

  /// Fetches the minimum age requirement from the backend.
  Future<int> getMinimumAge() async {
    AppLogger.debug(
      'Fetching verification config',
      operation: 'AuthRemoteDatasource.getMinimumAge',
    );

    final response = await _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.verificationConfig,
    );

    final body = response.data;
    if (body == null) return 60;

    final data = body['data'];
    if (data is Map<String, Object?>) {
      final minimumAge = data['minimumAge'];
      if (minimumAge is int) return minimumAge;
      if (minimumAge is num) return minimumAge.toInt();
    }

    return 60;
  }

  /// Verifies ID pre-registration with the ID photo (multipart upload).
  ///
  /// Returns the raw response so the caller can extract auditId.
  Future<Response<Map<String, Object?>>> verifyIdPreRegister({
    required String idPhotoFrontPath,
    Map<String, dynamic>? frontendOcrData,
    String? deviceFingerprint,
  }) async {
    AppLogger.debug(
      'Verifying ID pre-register',
      operation: 'AuthRemoteDatasource.verifyIdPreRegister',
    );

    final formMap = <String, dynamic>{
      'idFront': await MultipartFile.fromFile(
        idPhotoFrontPath,
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    };

    if (frontendOcrData != null) {
      formMap['frontendOcrData'] = jsonEncode(frontendOcrData);
    }

    if (deviceFingerprint != null && deviceFingerprint.isNotEmpty) {
      formMap['deviceFingerprint'] = deviceFingerprint;
    }

    final formData = FormData.fromMap(formMap);

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.verifyIdPreRegister,
      data: formData,
      receiveTimeout: const Duration(seconds: 60),
    );
  }

  // ---------------------------------------------------------------------------
  // User session
  // ---------------------------------------------------------------------------

  /// Fetches the authenticated user's profile from `/user/me`.
  Future<Response<Map<String, Object?>>> fetchUserMe() {
    AppLogger.debug(
      'Fetching /user/me',
      operation: 'AuthRemoteDatasource.fetchUserMe',
    );

    return _dioClient.get<Map<String, Object?>>(ApiEndpoints.userMe);
  }
}
