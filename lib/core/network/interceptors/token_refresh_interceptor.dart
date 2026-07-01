import 'dart:async';

import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Callback invoked when a token refresh fails irrecoverably — the consumer
/// (usually the DI layer) should clear auth state and redirect to login.
typedef OnSessionExpired = void Function();

/// Callback to sync the new access token into the in-memory session manager.
typedef OnTokenRefreshed = void Function(String newAccessToken);

/// Intercepts 401 responses and transparently refreshes the access token.
///
/// Concurrent requests that hit a 401 while a refresh is already in-flight
/// are queued and replayed once the new token is available. If the refresh
/// itself fails, all queued requests are rejected and [onSessionExpired] is
/// called so the app can redirect to the login screen.
///
/// Auth endpoints (`/auth/*`) are never retried — they are public and
/// a 401 on them indicates bad credentials, not an expired token.
final class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required SecureStorage secureStorage,
    required OnSessionExpired onSessionExpired,
    OnTokenRefreshed? onTokenRefreshed,
  }) : _dio = dio,
       _secureStorage = secureStorage,
       _onSessionExpired = onSessionExpired,
       _onTokenRefreshed = onTokenRefreshed;

  final Dio _dio;
  final SecureStorage _secureStorage;
  final OnTokenRefreshed? _onTokenRefreshed;
  final OnSessionExpired _onSessionExpired;

  /// Guards concurrent refresh attempts — only one refresh flies at a time.
  bool _isRefreshing = false;

  /// Prevents duplicate onSessionExpired callbacks when multiple requests fail
  /// simultaneously after a session has already been cleared.
  bool _sessionExpiredNotified = false;

  /// Queued request-retry completers waiting for the refresh to finish.
  final List<_PendingRequest> _pendingRequests = [];

  // ---------------------------------------------------------------------------
  // Error handler — triggers refresh on 401
  // ---------------------------------------------------------------------------

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    if (statusCode != 401 || _isAuthEndpoint(requestPath)) {
      handler.next(err);
      return;
    }

    // Prevent infinite retry loops — each request gets exactly one retry.
    if (err.requestOptions.extra['_hasRetried'] == true) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      // Another request is already refreshing — queue this one.
      _enqueueAndWait(err.requestOptions, handler);
      return;
    }

    await _refreshAndRetry(err.requestOptions, handler);
  }

  // ---------------------------------------------------------------------------
  // Core refresh logic
  // ---------------------------------------------------------------------------

  Future<void> _refreshAndRetry(
    RequestOptions failedOptions,
    ErrorInterceptorHandler handler,
  ) async {
    _isRefreshing = true;

    try {
      final newAccessToken = await _performTokenRefresh();
      _replayPendingRequests(newAccessToken);
      await _retryRequest(failedOptions, newAccessToken, handler);
    } on Object catch (refreshError, stackTrace) {
      _rejectPendingRequests(refreshError);

      if (_isDefinitiveAuthRejection(refreshError)) {
        // The refresh token itself was rejected (401/403). The session is
        // genuinely dead — clear it and route to login.
        AppLogger.error(
          'Refresh token rejected (auth) — clearing session',
          operation: 'TokenRefreshInterceptor',
          error: refreshError,
          stackTrace: stackTrace,
        );
        await _clearSessionAndNotify();
        handler.reject(
          DioException(
            requestOptions: failedOptions,
            error: refreshError,
            message: 'Session expired. Please sign in again.',
            type: DioExceptionType.unknown,
          ),
        );
      } else {
        // Transient failure — network/DNS/timeout, 5xx, or a malformed
        // response. Do NOT clear the session: a momentary network blip must
        // not log the user out. If the session really is revoked server-side,
        // the NEXT request's refresh will get a definitive 401 and clear then.
        // Fail just this request with a network-flavored error so the caller
        // can show "check your connection" + retry, not "sign in again".
        AppLogger.warning(
          'Token refresh failed transiently — keeping session intact',
          operation: 'TokenRefreshInterceptor',
          context: {'error': refreshError.toString()},
        );
        handler.reject(
          DioException(
            requestOptions: failedOptions,
            error: refreshError,
            message: 'Network problem reaching the server. Please try again.',
            type: DioExceptionType.connectionError,
          ),
        );
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// True only when the session is unrecoverably dead.
  /// Covers:
  ///  - No refresh token in storage (never logged in / storage cleared)
  ///  - Backend 400/401/403 on the refresh endpoint (expired/revoked token)
  /// Network errors, timeouts, 5xx are transient and must NOT clear the session.
  bool _isDefinitiveAuthRejection(Object error) {
    if (error is StateError && error.message == 'No refresh token available') {
      return true;
    }
    if (error is DioException && error.type == DioExceptionType.badResponse) {
      final code = error.response?.statusCode;
      return code == 400 || code == 401 || code == 403;
    }
    return false;
  }

  /// Calls `POST /auth/refresh-token` with the stored refresh token.
  /// Returns the new access token on success.
  Future<String> _performTokenRefresh() async {
    final refreshTokenResult = await _secureStorage.readRefreshToken();
    final refreshToken = refreshTokenResult.valueOrNull;

    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token available');
    }

    AppLogger.debug(
      'Attempting token refresh',
      operation: 'TokenRefreshInterceptor',
    );

    final refreshResponse = await _dio.post<Map<String, Object?>>(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );

    // The backend returns the new access token via the `Jwt-Token` response
    // header, not the JSON body. AuthInterceptor (which runs before this code
    // gets control back) already extracted it and wrote it to SecureStorage.
    final stored = await _secureStorage.readAccessToken();
    final newAccessToken = stored.valueOrNull;

    // If the backend rotates refresh tokens, persist the new one so subsequent
    // 401 retries don't get "No refresh token available" after the first refresh.
    final responseBody = refreshResponse.data;
    if (responseBody != null) {
      final bodyData = responseBody['data'];
      if (bodyData is Map) {
        final newRefreshToken = bodyData['refreshToken'];
        if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
          await _secureStorage.saveRefreshToken(newRefreshToken);
        }
      }
    }

    if (newAccessToken == null || newAccessToken.isEmpty) {
      throw StateError('Invalid access token in refresh response');
    }

    _onTokenRefreshed?.call(newAccessToken);

    AppLogger.info(
      'Token refresh succeeded — in-memory token synced',
      operation: 'TokenRefreshInterceptor',
    );

    return newAccessToken;
  }

  // ---------------------------------------------------------------------------
  // Request retry
  // ---------------------------------------------------------------------------

  Future<void> _retryRequest(
    RequestOptions original,
    String newAccessToken,
    ErrorInterceptorHandler handler,
  ) async {
    original
      ..headers['Authorization'] = 'Bearer $newAccessToken'
      ..extra['_hasRetried'] = true;

    try {
      final retryResponse = await _dio.fetch<Object?>(original);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.reject(retryError);
    }
  }

  // ---------------------------------------------------------------------------
  // Pending request queue
  // ---------------------------------------------------------------------------

  void _enqueueAndWait(
    RequestOptions options,
    ErrorInterceptorHandler handler,
  ) {
    final completer = Completer<String>();

    _pendingRequests.add(
      _PendingRequest(options: options, tokenCompleter: completer),
    );

    completer.future
        .then((newToken) async {
          options
            ..headers['Authorization'] = 'Bearer $newToken'
            ..extra['_hasRetried'] = true;

          try {
            final response = await _dio.fetch<Object?>(options);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.reject(retryError);
          }
        })
        .catchError((Object error) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: error,
              type: DioExceptionType.unknown,
            ),
          );
        });
  }

  void _replayPendingRequests(String newToken) {
    for (final pending in _pendingRequests) {
      pending.tokenCompleter.complete(newToken);
    }
    _pendingRequests.clear();
  }

  void _rejectPendingRequests(Object error) {
    for (final pending in _pendingRequests) {
      pending.tokenCompleter.completeError(error);
    }
    _pendingRequests.clear();
  }

  // ---------------------------------------------------------------------------
  // Session cleanup
  // ---------------------------------------------------------------------------

  Future<void> _clearSessionAndNotify() async {
    await _secureStorage.clearAllSecureData();
    if (!_sessionExpiredNotified) {
      _sessionExpiredNotified = true;
      _onSessionExpired();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isAuthEndpoint(String path) => path.startsWith('/auth/');
}

// ---------------------------------------------------------------------------
// Internal types
// ---------------------------------------------------------------------------

final class _PendingRequest {
  const _PendingRequest({required this.options, required this.tokenCompleter});

  final RequestOptions options;
  final Completer<String> tokenCompleter;
}
