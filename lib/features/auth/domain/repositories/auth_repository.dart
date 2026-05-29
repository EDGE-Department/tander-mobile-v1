import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

/// Contract for all authentication operations.
///
/// Implementations live in the data layer and may use Dio, secure storage, or
/// any other infrastructure concern. The domain layer only knows this
/// interface — it never sees the concrete implementation.
abstract interface class AuthRepository {
  /// Authenticates with [email] and [password], returning the session on success.
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  });

  /// Terminates the current session and clears persisted tokens.
  Future<Result<void>> signOut();

  /// Creates a new account and returns the initial session.
  Future<Result<AuthSession>> register({
    String? email,
    String? phone,
    required String password,
    required String auditId,
  });

  /// Fetches the currently authenticated user's session from the server.
  Future<Result<AuthSession>> getCurrentUser();

  /// Attempts to restore a session from persisted tokens on cold start.
  ///
  /// Returns `true` if the session was restored, `false` if the user must
  /// sign in manually.
  Future<Result<bool>> bootstrapSession();

  /// Sends a password-reset code to [email] or [phone] (exactly one required).
  Future<Result<void>> requestPasswordReset({String? email, String? phone});

  /// Verifies the one-time password sent during password reset.
  /// Returns the one-time reset token (UUID, valid 5 minutes).
  Future<Result<String>> verifyResetOtp({
    String? email,
    String? phone,
    required String otp,
  });

  /// Sets a new password using the reset token from [verifyResetOtp].
  Future<Result<void>> resetPassword({
    String? email,
    String? phone,
    required String resetToken,
    required String newPassword,
  });

  /// Re-sends the email verification message to [email].
  Future<Result<void>> resendEmailVerification({required String email});

  /// Sends a registration OTP to [email] or [phone] for account verification.
  Future<Result<void>> sendRegistrationOtp({String? email, String? phone});

  /// Verifies the registration OTP. Returns true if valid.
  Future<Result<bool>> verifyRegistrationOtp({
    String? email,
    String? phone,
    required String otp,
  });

  /// Checks whether [email] is available for registration.
  Future<Result<bool>> checkEmailAvailability({required String email});

  /// Checks whether [username] is available for registration.
  Future<Result<bool>> checkUsernameAvailability({required String username});

  /// Checks whether [phone] is available for registration.
  Future<Result<bool>> checkPhoneAvailability({required String phone});

  /// Fetches the minimum age requirement from the backend.
  Future<Result<int>> getMinimumAge();

  /// Verifies ID pre-registration with the ID photo.
  ///
  /// Returns the auditId on success.
  Future<Result<String>> verifyIdPreRegister({
    required String idPhotoFrontPath,
    Map<String, dynamic>? frontendOcrData,
    String? deviceFingerprint,
  });
}
