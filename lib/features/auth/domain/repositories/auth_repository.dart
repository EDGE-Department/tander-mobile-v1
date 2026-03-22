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
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  });

  /// Fetches the currently authenticated user's session from the server.
  Future<Result<AuthSession>> getCurrentUser();

  /// Attempts to restore a session from persisted tokens on cold start.
  ///
  /// Returns `true` if the session was restored, `false` if the user must
  /// sign in manually.
  Future<Result<bool>> bootstrapSession();

  /// Sends a password-reset email to [email].
  Future<Result<void>> requestPasswordReset({required String email});

  /// Verifies the one-time password sent during password reset.
  Future<Result<void>> verifyResetOtp({
    required String email,
    required String otp,
  });

  /// Sets a new password using a verified OTP.
  Future<Result<void>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });

  /// Re-sends the email verification message to [email].
  Future<Result<void>> resendEmailVerification({required String email});

  /// Sends a registration OTP to [email] for account verification.
  Future<Result<void>> sendRegistrationOtp({required String email});

  /// Verifies the registration OTP for [email].
  Future<Result<void>> verifyRegistrationOtp({
    required String email,
    required String otp,
  });

  /// Checks whether [email] is available for registration.
  Future<Result<bool>> checkEmailAvailability({required String email});

  /// Checks whether [username] is available for registration.
  Future<Result<bool>> checkUsernameAvailability({required String username});
}
