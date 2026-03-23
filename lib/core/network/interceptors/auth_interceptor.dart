import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Attaches the stored access token to every outgoing request and extracts
/// rotated tokens from the `Jwt-Token` response header.
///
/// **Request side**: reads the access token from [SecureStorage] and sets the
/// `Authorization: Bearer {token}` header. Public auth endpoints (paths
/// starting with `/auth/` except `/auth/refresh-token`) are skipped
/// because they must not carry a bearer token — doing so causes the backend
/// JWT filter to reject the request.
///
/// **Response side**: the backend silently rotates the access token by
/// returning a `Jwt-Token: Bearer {newToken}` header on any authenticated
/// response. This interceptor strips the `Bearer ` prefix and persists the
/// new value so subsequent requests use the freshest token.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;

  // ---------------------------------------------------------------------------
  // Request — attach bearer token
  // ---------------------------------------------------------------------------

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    final tokenResult = await _secureStorage.readAccessToken();
    final accessToken = tokenResult.valueOrNull;

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Stamp request start time so the logging interceptor can compute elapsed.
    options.extra['_requestStartMs'] =
        DateTime.now().millisecondsSinceEpoch;

    handler.next(options);
  }

  // ---------------------------------------------------------------------------
  // Response — extract rotated token from Jwt-Token header
  // ---------------------------------------------------------------------------

  @override
  Future<void> onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) async {
    await _extractAndStoreRotatedToken(response);
    handler.next(response);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` for public auth endpoints that must NOT carry a bearer
  /// token. The refresh-token endpoint is excluded from this check because
  /// it legitimately sends the (old) access token.
  bool _isPublicAuthEndpoint(String path) {
    if (!path.startsWith('/auth/')) return false;
    if (path.startsWith('/auth/refresh-token')) return false;
    return true;
  }

  /// Reads the `Jwt-Token` response header (case-insensitive thanks to Dio's
  /// internal normalisation), strips the `Bearer ` prefix, and persists the
  /// new access token.
  Future<void> _extractAndStoreRotatedToken(
    Response<Object?> response,
  ) async {
    // Dio lower-cases header names, so `jwt-token` matches `Jwt-Token`.
    final rawJwtHeader = response.headers.value('jwt-token');
    if (rawJwtHeader == null || rawJwtHeader.isEmpty) return;

    final freshToken = rawJwtHeader.startsWith('Bearer ')
        ? rawJwtHeader.substring(7)
        : rawJwtHeader;

    if (freshToken.isEmpty) return;

    // Only persist when an existing session is active — prevents a
    // completed in-flight request from resurrecting a stale token after
    // logout.
    final existingResult = await _secureStorage.readAccessToken();
    if (existingResult.valueOrNull == null) return;

    await _secureStorage.saveAccessToken(freshToken);

    AppLogger.debug(
      'Rotated access token from Jwt-Token header',
      operation: 'AuthInterceptor',
    );
  }
}
