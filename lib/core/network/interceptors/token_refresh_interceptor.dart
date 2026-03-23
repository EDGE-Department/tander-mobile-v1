import 'dart:async';

import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Callback invoked when a token refresh fails irrecoverably — the consumer
/// (usually the DI layer) should clear auth state and redirect to login.
typedef OnSessionExpired = void Function();

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
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final SecureStorage _secureStorage;
  final OnSessionExpired _onSessionExpired;

  /// Guards concurrent refresh attempts — only one refresh flies at a time.
  bool _isRefreshing = false;

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
      AppLogger.error(
        'Token refresh failed — clearing session',
        operation: 'TokenRefreshInterceptor',
        error: refreshError,
        stackTrace: stackTrace,
      );

      _rejectPendingRequests(refreshError);
      await _clearSessionAndNotify();

      handler.reject(
        DioException(
          requestOptions: failedOptions,
          error: refreshError,
          message: 'Session expired. Please sign in again.',
          type: DioExceptionType.unknown,
        ),
      );
    } finally {
      _isRefreshing = false;
    }
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

    final response = await _dio.post<Map<String, Object?>>(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );

    final responseBody = response.data;
    if (responseBody == null) {
      throw StateError('Empty response from refresh-token endpoint');
    }

    final newAccessToken = responseBody['accessToken'];
    final newRefreshToken = responseBody['refreshToken'];

    if (newAccessToken is! String || newAccessToken.isEmpty) {
      throw StateError('Invalid access token in refresh response');
    }

    await _secureStorage.saveAccessToken(newAccessToken);

    if (newRefreshToken is String && newRefreshToken.isNotEmpty) {
      await _secureStorage.saveRefreshToken(newRefreshToken);
    }

    AppLogger.info(
      'Token refresh succeeded',
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

    completer.future.then((newToken) async {
      options
        ..headers['Authorization'] = 'Bearer $newToken'
        ..extra['_hasRetried'] = true;

      try {
        final response = await _dio.fetch<Object?>(options);
        handler.resolve(response);
      } on DioException catch (retryError) {
        handler.reject(retryError);
      }
    }).catchError((Object error) {
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
    _onSessionExpired();
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
  const _PendingRequest({
    required this.options,
    required this.tokenCompleter,
  });

  final RequestOptions options;
  final Completer<String> tokenCompleter;
}
