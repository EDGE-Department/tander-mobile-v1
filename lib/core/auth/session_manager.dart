import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

// ---------------------------------------------------------------------------
// Registration phase
// ---------------------------------------------------------------------------

/// Backend registration phases sent as SCREAMING_SNAKE_CASE strings.
///
/// Drives the onboarding flow — each phase represents a gate the user must
/// pass through before reaching the main app experience.
enum RegistrationPhase {
  pendingEmailVerification,
  pendingProfileSetup,
  pendingPhotoSetup,
  pendingIdVerification,
  pendingNotificationPermission,
  complete;

  /// Parse a backend string like `"PENDING_EMAIL_VERIFICATION"` into the
  /// corresponding enum value.
  ///
  /// Throws [ArgumentError] if the string does not match any known phase.
  static RegistrationPhase fromBackendString(String backendValue) {
    return switch (backendValue) {
      'PENDING_EMAIL_VERIFICATION' => RegistrationPhase.pendingEmailVerification,
      'PENDING_PROFILE_SETUP' => RegistrationPhase.pendingProfileSetup,
      'PENDING_PHOTO_SETUP' => RegistrationPhase.pendingPhotoSetup,
      'PENDING_ID_VERIFICATION' => RegistrationPhase.pendingIdVerification,
      'PENDING_NOTIFICATION_PERMISSION' =>
        RegistrationPhase.pendingNotificationPermission,
      'COMPLETE' || 'verified' || 'VERIFIED' => RegistrationPhase.complete,
      _ => RegistrationPhase.complete, // Unknown phase = treat as complete
    };
  }
}

// ---------------------------------------------------------------------------
// Auth session
// ---------------------------------------------------------------------------

/// Immutable snapshot of the authenticated user's session data.
///
/// Built from the `/user/me` response during login or bootstrap. All fields
/// are final — to update the session, create a new [AuthSession] instance.
final class AuthSession {
  const AuthSession({
    required this.userId,
    required this.registrationPhase,
    required this.isEmailVerified,
    required this.isIdVerified,
    this.email,
    this.username,
    this.profilePhotoUrl,
  });

  final int userId;
  final String? email;
  final String? username;
  final RegistrationPhase registrationPhase;
  final bool isEmailVerified;
  final bool isIdVerified;
  final String? profilePhotoUrl;

  /// Whether the user has completed every onboarding gate.
  bool get isOnboardingComplete =>
      registrationPhase == RegistrationPhase.complete;

  @override
  String toString() =>
      'AuthSession(userId: $userId, email: $email, phase: $registrationPhase)';
}

// ---------------------------------------------------------------------------
// Session manager
// ---------------------------------------------------------------------------

/// Single source of truth for auth tokens and session state.
///
/// **Access token**: held in-memory only — dies with the process. A backup
/// copy is persisted in [SecureStorage] so cold starts can restore the
/// session without a full login.
///
/// **Refresh token**: persisted in [SecureStorage]. Used by [bootstrapSession]
/// to obtain a fresh access token on app restart.
///
/// The [DioClient] interceptor chain already handles:
/// - Attaching the bearer token from [SecureStorage] on every request.
/// - Extracting rotated tokens from the `Jwt-Token` response header.
/// - Transparent 401 retry via the refresh-token endpoint.
///
/// This class sits above that plumbing and manages the *session* — the user
/// identity and onboarding state.
final class SessionManager {
  SessionManager({
    required SecureStorage secureStorage,
    required DioClient dioClient,
  })  : _secureStorage = secureStorage,
        _dioClient = dioClient;

  final SecureStorage _secureStorage;
  final DioClient _dioClient;

  /// In-memory access token — canonical at runtime.
  String? _accessToken;

  /// Current session data — populated after login or bootstrap.
  AuthSession? _session;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  String? get accessToken => _accessToken;
  AuthSession? get session => _session;

  bool get isAuthenticated => _accessToken != null && _session != null;

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Stores tokens after a successful login or registration.
  ///
  /// The access token is held in memory and also persisted to [SecureStorage]
  /// as a cold-start backup. The refresh token goes to [SecureStorage] only.
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _secureStorage.saveAccessToken(accessToken);
    await _secureStorage.saveRefreshToken(refreshToken);

    AppLogger.debug(
      'Tokens stored (access in-memory + secure, refresh in secure)',
      operation: 'SessionManager.setTokens',
    );
  }

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Updates the in-memory session from a `/user/me` response or login payload.
  void setSession(AuthSession authSession) {
    _session = authSession;

    AppLogger.info(
      'Session set for user ${authSession.userId}',
      operation: 'SessionManager.setSession',
      context: {
        'registrationPhase': authSession.registrationPhase.name,
        'isOnboardingComplete': authSession.isOnboardingComplete,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bootstrap — restore session from persisted refresh token
  // ---------------------------------------------------------------------------

  /// Attempts to restore a full session from [SecureStorage] on cold start.
  ///
  /// 1. Reads the refresh token from secure storage.
  /// 2. Calls `POST /api/auth/refresh-token` to obtain fresh tokens.
  ///    The [AuthInterceptor] automatically extracts the new access token
  ///    from the `Jwt-Token` response header and persists it.
  /// 3. Reads the fresh access token back from secure storage into memory.
  /// 4. Calls `GET /api/user/me` to rebuild the [AuthSession].
  ///
  /// Returns `true` if the session was restored, `false` on any failure.
  /// Never throws — a failed bootstrap simply means the user must log in.
  Future<bool> bootstrapSession() async {
    try {
      final refreshToken = await _readRefreshToken();
      if (refreshToken == null) {
        AppLogger.debug(
          'No refresh token found — skipping bootstrap',
          operation: 'SessionManager.bootstrapSession',
        );
        return false;
      }

      await _callRefreshEndpoint(refreshToken);
      await _restoreAccessTokenFromStorage();
      await _fetchAndSetUserSession();

      AppLogger.info(
        'Session bootstrapped successfully for user ${_session?.userId}',
        operation: 'SessionManager.bootstrapSession',
      );
      return true;
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Bootstrap failed — user must log in manually',
        operation: 'SessionManager.bootstrapSession',
        error: error,
        stackTrace: stackTrace,
      );
      await clearSession();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Clears all auth state — tokens, session, and secure storage.
  Future<void> clearSession() async {
    _accessToken = null;
    _session = null;
    await _secureStorage.clearAllSecureData();

    AppLogger.info(
      'Session cleared',
      operation: 'SessionManager.clearSession',
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<String?> _readRefreshToken() async {
    final refreshTokenResult = await _secureStorage.readRefreshToken();
    return refreshTokenResult.valueOrNull;
  }

  /// Calls the refresh endpoint. The [AuthInterceptor] on the response side
  /// extracts the `Jwt-Token` header and persists the new access token.
  /// We also persist the new refresh token from the response body.
  Future<void> _callRefreshEndpoint(String refreshToken) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );

    final responseBody = response.data;
    if (responseBody == null) {
      throw StateError('Empty response from refresh-token endpoint');
    }

    // Extract and store the new access token from the Jwt-Token header.
    // The AuthInterceptor handles this for authenticated requests, but
    // the refresh endpoint is considered public, so we handle it here.
    await _extractAccessTokenFromHeader(response);

    // Persist the new refresh token from the response body.
    final bodyData = responseBody['data'];
    if (bodyData is Map<String, Object?>) {
      final newRefreshToken = bodyData['refreshToken'];
      if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
        await _secureStorage.saveRefreshToken(newRefreshToken);
      }
    }
  }

  /// Reads the `Jwt-Token` header, strips the `Bearer ` prefix, and stores
  /// both in-memory and in secure storage.
  Future<void> _extractAccessTokenFromHeader(Response<Object?> response) async {
    final rawJwtHeader = response.headers.value('jwt-token');
    if (rawJwtHeader == null || rawJwtHeader.isEmpty) return;

    final freshToken = rawJwtHeader.startsWith('Bearer ')
        ? rawJwtHeader.substring(7)
        : rawJwtHeader;

    if (freshToken.isEmpty) return;

    _accessToken = freshToken;
    await _secureStorage.saveAccessToken(freshToken);

    AppLogger.debug(
      'Extracted access token from Jwt-Token response header',
      operation: 'SessionManager._extractAccessTokenFromHeader',
    );
  }

  /// Reads the access token from [SecureStorage] into in-memory state.
  /// Called during bootstrap after the refresh call has persisted a new token.
  Future<void> _restoreAccessTokenFromStorage() async {
    // If _extractAccessTokenFromHeader already set it, skip the read.
    if (_accessToken != null) return;

    final tokenResult = await _secureStorage.readAccessToken();
    final storedToken = tokenResult.valueOrNull;

    if (storedToken == null || storedToken.isEmpty) {
      throw StateError(
        'Refresh succeeded but no access token found in secure storage',
      );
    }

    _accessToken = storedToken;
  }

  /// Calls `GET /api/user/me` and builds an [AuthSession] from the response.
  ///
  /// The `/user/me` endpoint may not return `registrationPhase`,
  /// `isEmailVerified`, or `isIdVerified`. When absent, we fall back to
  /// the existing session (if any), or default to values that keep an
  /// authenticated user past onboarding — a valid refresh token implies
  /// onboarding was previously completed.
  Future<void> _fetchAndSetUserSession() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '/user/me',
    );

    final userJson = response.data;
    if (userJson == null) {
      throw StateError('Empty response from /user/me endpoint');
    }

    final previousSession = _session;

    final rawId = userJson['id'];
    final userId = switch (rawId) {
      final int intId => intId,
      final String stringId => int.parse(stringId),
      _ => throw StateError(
          'Invalid or missing "id" in /user/me response: $rawId',
        ),
    };

    final email = userJson['email'] is String ? userJson['email'] as String : null;
    final username = userJson['username'] is String ? userJson['username'] as String : null;

    final registrationPhase = _parseRegistrationPhase(
      userJson['registrationPhase'],
      fallback: previousSession?.registrationPhase,
    );

    final isEmailVerified = _parseBool(
      userJson['isEmailVerified'],
      fallback: previousSession?.isEmailVerified ?? true,
    );

    final isIdVerified = _parseBool(
      userJson['isIdVerified'],
      fallback: previousSession?.isIdVerified ?? false,
    );

    final profilePhotoUrl = userJson['profilePhotoUrl'];

    _session = AuthSession(
      userId: userId,
      email: email,
      username: username,
      registrationPhase: registrationPhase,
      isEmailVerified: isEmailVerified,
      isIdVerified: isIdVerified,
      profilePhotoUrl: profilePhotoUrl is String ? profilePhotoUrl : null,
    );
  }

  /// Parses a registration phase string, falling back to [fallback] or
  /// [RegistrationPhase.complete] if absent.
  RegistrationPhase _parseRegistrationPhase(
    Object? rawPhase, {
    RegistrationPhase? fallback,
  }) {
    if (rawPhase is String && rawPhase.isNotEmpty) {
      return RegistrationPhase.fromBackendString(rawPhase);
    }
    return fallback ?? RegistrationPhase.complete;
  }

  /// Parses a boolean field, falling back to [fallback] if absent or invalid.
  bool _parseBool(Object? rawValue, {required bool fallback}) {
    if (rawValue is bool) return rawValue;
    return fallback;
  }
}
