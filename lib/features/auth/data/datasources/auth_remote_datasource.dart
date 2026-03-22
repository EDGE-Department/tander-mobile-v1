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
      context: {'email': request.email},
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

  /// Requests a password-reset OTP to be sent to [email].
  Future<void> requestPasswordReset({required String email}) async {
    AppLogger.debug(
      'Requesting password reset',
      operation: 'AuthRemoteDatasource.requestPasswordReset',
      context: {'email': email},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.forgotPassword,
      data: ForgotPasswordRequestDto(email: email).toJson(),
    );
  }

  /// Verifies the password-reset OTP and returns the response containing
  /// the one-time reset token.
  Future<Response<Map<String, Object?>>> verifyResetOtp({
    required String email,
    required String otp,
  }) {
    AppLogger.debug(
      'Verifying reset OTP',
      operation: 'AuthRemoteDatasource.verifyResetOtp',
      context: {'email': email},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.verifyResetOtp,
      data: VerifyResetOtpRequestDto(email: email, code: otp).toJson(),
    );
  }

  /// Resets the password using the one-time reset token from [verifyResetOtp].
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    AppLogger.debug(
      'Resetting password',
      operation: 'AuthRemoteDatasource.resetPassword',
      context: {'email': email},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.resetPassword,
      data: ResetPasswordRequestDto(
        email: email,
        resetToken: otp,
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
  // Registration OTP
  // ---------------------------------------------------------------------------

  /// Sends a registration OTP to the given email.
  Future<void> sendRegistrationOtp({required String email}) async {
    AppLogger.debug(
      'Sending registration OTP',
      operation: 'AuthRemoteDatasource.sendRegistrationOtp',
      context: {'email': email},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.sendOtp,
      data: SendOtpRequestDto(contact: email, type: 'EMAIL').toJson(),
    );
  }

  /// Verifies the registration OTP.
  Future<void> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    AppLogger.debug(
      'Verifying registration OTP',
      operation: 'AuthRemoteDatasource.verifyRegistrationOtp',
      context: {'email': email},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.verifyOtp,
      data: VerifyRegistrationOtpRequestDto(contact: email, otp: otp).toJson(),
    );
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

    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.checkEmail,
      queryParameters: {'email': email},
    );

    final body = response.data;
    if (body == null) return false;

    final isAvailable = body['available'];
    return isAvailable is bool && isAvailable;
  }

  /// Returns `true` if the username is available for registration.
  Future<bool> checkUsernameAvailability({required String username}) async {
    AppLogger.debug(
      'Checking username availability',
      operation: 'AuthRemoteDatasource.checkUsernameAvailability',
    );

    final response = await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.checkUsername,
      queryParameters: {'username': username},
    );

    final body = response.data;
    if (body == null) return false;

    final isAvailable = body['available'];
    return isAvailable is bool && isAvailable;
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
