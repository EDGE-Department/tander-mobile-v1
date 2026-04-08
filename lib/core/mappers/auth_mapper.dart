import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Pure functions converting auth-related DTOs and raw JSON to domain models.
///
/// All conversions are null-safe with documented fallback behaviour.
/// The mapper never performs I/O or mutates external state.
abstract final class AuthMapper {
  /// Builds an [AuthSession] from the raw `/user/me` JSON response.
  ///
  /// Required fields: `id` (int or numeric string), `email`, `username`.
  ///
  /// Optional fields fall back to safe defaults:
  /// - `registrationPhase` -> [RegistrationPhase.complete]
  /// - `isEmailVerified` -> `true` (a valid token implies prior verification)
  /// - `isIdVerified` -> `false`
  /// - `profilePhotoUrl` -> `null`
  static AuthSession mapToAuthSession(Map<String, Object?> userMeJson) {
    final userId = _parseUserId(userMeJson['id']);
    final email = _parseOptionalString(userMeJson['email']) ?? '';
    final username = _parseOptionalString(userMeJson['username']) ?? '';

    final profileCompleted =
        _parseBool(userMeJson['profileCompleted'], fallback: true);
    final registrationPhase = _deriveRegistrationPhase(
      userMeJson['registrationPhase'],
      profileCompleted,
    );
    final isEmailVerified =
        _parseBool(userMeJson['isEmailVerified'], fallback: true);
    final isIdVerified =
        _parseBool(userMeJson['isIdVerified'], fallback: false);
    final profilePhotoUrl = _parseOptionalString(userMeJson['profilePhotoUrl']);

    return AuthSession(
      userId: userId,
      email: email,
      username: username,
      registrationPhase: registrationPhase,
      isEmailVerified: isEmailVerified,
      isIdVerified: isIdVerified,
      profilePhotoUrl: profilePhotoUrl,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Parses `id` from either an [int] or a numeric [String].
  ///
  /// Throws [FormatException] if the value is missing or non-numeric.
  static int _parseUserId(Object? rawId) {
    return switch (rawId) {
      final int intId => intId,
      final String stringId => int.parse(stringId),
      _ => throw FormatException(
          'Invalid or missing "id" in /user/me response: $rawId',
        ),
    };
  }

  /// Returns a [String] if present and non-empty, otherwise `null`.
  static String? _parseOptionalString(Object? rawValue) {
    if (rawValue is String && rawValue.isNotEmpty) return rawValue;
    return null;
  }

  /// Converts a backend phase string (e.g. `"PENDING_EMAIL_VERIFICATION"`)
  /// into a [RegistrationPhase].
  ///
  /// Falls back to [RegistrationPhase.complete] when the value is absent or
  /// unrecognised, logging a warning for unrecognised values.
  /// Derives the registration phase from either the explicit backend field
  /// or from `profileCompleted`. If `profileCompleted` is false and no
  /// explicit phase is given, the user still needs to complete profile setup.
  static RegistrationPhase _deriveRegistrationPhase(
    Object? rawPhase,
    bool profileCompleted,
  ) {
    if (rawPhase is String && rawPhase.isNotEmpty) {
      try {
        return RegistrationPhase.fromBackendString(rawPhase);
      } on ArgumentError {
        AppLogger.warning(
          'Unrecognised registration phase "$rawPhase"',
          operation: 'AuthMapper._deriveRegistrationPhase',
        );
      }
    }

    // No explicit phase — derive from profile completion status
    if (!profileCompleted) {
      return RegistrationPhase.pendingProfileSetup;
    }
    return RegistrationPhase.complete;
  }

  /// Parses a boolean field with a safe [fallback] for missing/invalid values.
  static bool _parseBool(Object? rawValue, {required bool fallback}) {
    if (rawValue is bool) return rawValue;
    return fallback;
  }
}
