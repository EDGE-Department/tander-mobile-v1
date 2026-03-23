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

    final registrationPhase =
        _parseRegistrationPhase(userMeJson['registrationPhase']);
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

  /// Returns a non-empty [String] or throws [FormatException].
  static String _requireString(Object? rawValue, {required String fieldName}) {
    if (rawValue is String && rawValue.isNotEmpty) return rawValue;
    throw FormatException(
      'Invalid or missing "$fieldName" in /user/me response',
    );
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
  static RegistrationPhase _parseRegistrationPhase(Object? rawPhase) {
    if (rawPhase is! String || rawPhase.isEmpty) {
      return RegistrationPhase.complete;
    }

    try {
      return RegistrationPhase.fromBackendString(rawPhase);
    } on ArgumentError {
      AppLogger.warning(
        'Unrecognised registration phase "$rawPhase" — defaulting to COMPLETE',
        operation: 'AuthMapper._parseRegistrationPhase',
      );
      return RegistrationPhase.complete;
    }
  }

  /// Parses a boolean field with a safe [fallback] for missing/invalid values.
  static bool _parseBool(Object? rawValue, {required bool fallback}) {
    if (rawValue is bool) return rawValue;
    return fallback;
  }
}
