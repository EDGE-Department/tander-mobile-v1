import 'dart:convert';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/storage/local_storage.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Manages local persistence of auth tokens and cached user session.
///
/// **Tokens** (access + refresh) are stored in [SecureStorage] — encrypted,
/// suitable for credentials.
///
/// **User session cache** is stored in [LocalStorage] (SharedPreferences) as
/// serialised JSON — non-sensitive display data that speeds up cold starts by
/// avoiding a network round-trip before the first frame.
final class AuthLocalDatasource {
  const AuthLocalDatasource({
    required SecureStorage secureStorage,
    required LocalStorage localStorage,
  })  : _secureStorage = secureStorage,
        _localStorage = localStorage;

  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  // ---------------------------------------------------------------------------
  // Token operations
  // ---------------------------------------------------------------------------

  /// Persists both tokens — access in secure storage (cold-start backup),
  /// refresh in secure storage (primary persistence).
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.saveAccessToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);

    AppLogger.debug(
      'Tokens saved to secure storage',
      operation: 'AuthLocalDatasource.saveTokens',
    );
  }

  /// Reads the cold-start backup access token, or `null` if absent.
  Future<String?> readAccessToken() async {
    final tokenResult = await _secureStorage.readAccessToken();
    return tokenResult.valueOrNull;
  }

  /// Reads the persisted refresh token, or `null` if absent.
  Future<String?> readRefreshToken() async {
    final tokenResult = await _secureStorage.readRefreshToken();
    return tokenResult.valueOrNull;
  }

  /// Removes both tokens from secure storage.
  Future<void> clearTokens() async {
    await _secureStorage.deleteAccessToken();
    await _secureStorage.deleteRefreshToken();

    AppLogger.debug(
      'Tokens cleared from secure storage',
      operation: 'AuthLocalDatasource.clearTokens',
    );
  }

  // ---------------------------------------------------------------------------
  // User session cache
  // ---------------------------------------------------------------------------

  /// Serialises [session] to JSON and stores it in local storage.
  Future<void> cacheUser(AuthSession session) async {
    final sessionJson = jsonEncode(_authSessionToMap(session));
    await _localStorage.cacheUserJson(sessionJson);

    AppLogger.debug(
      'User session cached for userId ${session.userId}',
      operation: 'AuthLocalDatasource.cacheUser',
    );
  }

  /// Returns the cached [AuthSession] from local storage, or `null` if
  /// no cache exists or the cached data is corrupt.
  AuthSession? getCachedUser() {
    final jsonResult = _localStorage.getCachedUserJson();
    final rawJson = jsonResult.valueOrNull;
    if (rawJson == null || rawJson.isEmpty) return null;

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, Object?>) return null;
      return _authSessionFromMap(decoded);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to deserialise cached user session — cache will be ignored',
        operation: 'AuthLocalDatasource.getCachedUser',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Removes the cached user session from local storage.
  Future<void> clearCachedUser() async {
    await _localStorage.clearCachedUser();

    AppLogger.debug(
      'Cached user session cleared',
      operation: 'AuthLocalDatasource.clearCachedUser',
    );
  }

  // ---------------------------------------------------------------------------
  // Private serialisation helpers
  // ---------------------------------------------------------------------------

  /// Converts an [AuthSession] to a JSON-compatible map.
  static Map<String, Object?> _authSessionToMap(AuthSession session) {
    return {
      'userId': session.userId,
      'email': session.email,
      'username': session.username,
      'registrationPhase': session.registrationPhase.name,
      'isEmailVerified': session.isEmailVerified,
      'isIdVerified': session.isIdVerified,
      'profilePhotoUrl': session.profilePhotoUrl,
    };
  }

  /// Reconstructs an [AuthSession] from a previously cached map.
  ///
  /// Throws on missing or invalid required fields so the caller can
  /// discard the corrupt cache entry.
  static AuthSession _authSessionFromMap(Map<String, Object?> map) {
    final rawId = map['userId'];
    final userId = switch (rawId) {
      final int intId => intId,
      final String stringId => int.parse(stringId),
      _ => throw FormatException('Invalid cached userId: $rawId'),
    };

    final email = map['email'];
    if (email is! String || email.isEmpty) {
      throw const FormatException('Invalid cached email');
    }

    final username = map['username'];
    if (username is! String || username.isEmpty) {
      throw const FormatException('Invalid cached username');
    }

    final registrationPhase = _parsePhaseFromCacheName(map['registrationPhase']);

    final isEmailVerified = map['isEmailVerified'];
    final isIdVerified = map['isIdVerified'];
    final profilePhotoUrl = map['profilePhotoUrl'];

    return AuthSession(
      userId: userId,
      email: email,
      username: username,
      registrationPhase: registrationPhase,
      isEmailVerified: isEmailVerified is bool ? isEmailVerified : true,
      isIdVerified: isIdVerified is bool ? isIdVerified : false,
      profilePhotoUrl:
          profilePhotoUrl is String && profilePhotoUrl.isNotEmpty
              ? profilePhotoUrl
              : null,
    );
  }

  /// Converts the Dart enum `.name` string (camelCase) back into a
  /// [RegistrationPhase], defaulting to [RegistrationPhase.complete]
  /// for unrecognised or missing values.
  static RegistrationPhase _parsePhaseFromCacheName(Object? phaseName) {
    if (phaseName is! String || phaseName.isEmpty) {
      return RegistrationPhase.complete;
    }

    for (final phase in RegistrationPhase.values) {
      if (phase.name == phaseName) return phase;
    }

    AppLogger.warning(
      'Unrecognised cached registration phase "$phaseName" '
      '— defaulting to complete',
      operation: 'AuthLocalDatasource._parsePhaseFromCacheName',
    );
    return RegistrationPhase.complete;
  }
}
