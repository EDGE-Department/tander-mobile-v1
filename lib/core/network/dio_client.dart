import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/config/env_config.dart';
import 'package:tander_flutter_v3/core/network/interceptors/auth_interceptor.dart';
import 'package:tander_flutter_v3/core/network/interceptors/logging_interceptor.dart';
import 'package:tander_flutter_v3/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:tander_flutter_v3/core/network/network_exception_handler.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';

const Duration _connectTimeout = Duration(seconds: 15);
const Duration _receiveTimeout = Duration(seconds: 15);

/// Typed HTTP client wrapper around [Dio].
///
/// Provides convenience methods (`get`, `post`, `put`, `patch`, `delete`)
/// that automatically unwrap the response data and map Dio errors to typed
/// [AppException] subclasses via [NetworkExceptionHandler].
///
/// Interceptor execution order (first → last):
/// 1. [LoggingInterceptor] — debug logging with masked auth headers
/// 2. [AuthInterceptor] — attaches bearer token, extracts rotated tokens
/// 3. [TokenRefreshInterceptor] — transparent 401 recovery
final class DioClient {
  DioClient({
    required SecureStorage secureStorage,
    required OnSessionExpired onSessionExpired,
    OnTokenRefreshed? onTokenRefreshed,
  }) : _dio = _createDio(
          secureStorage: secureStorage,
          onSessionExpired: onSessionExpired,
          onTokenRefreshed: onTokenRefreshed,
        );

  /// Test-only constructor that accepts a pre-configured [Dio] instance.
  DioClient.withDio(Dio dio) : _dio = dio;

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // HTTP methods
  // ---------------------------------------------------------------------------

  Future<Response<TResponse>> get<TResponse>(
    String path, {
    Map<String, Object>? queryParameters,
  }) =>
      _execute(() => _dio.get<TResponse>(
            path,
            queryParameters: queryParameters,
          ));

  Future<Response<TResponse>> post<TResponse>(
    String path, {
    Object? data,
    Map<String, Object>? queryParameters,
    Duration? receiveTimeout,
  }) =>
      _execute(() => _dio.post<TResponse>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: receiveTimeout != null
                ? Options(receiveTimeout: receiveTimeout)
                : null,
          ));

  Future<Response<TResponse>> put<TResponse>(
    String path, {
    Object? data,
  }) =>
      _execute(() => _dio.put<TResponse>(path, data: data));

  Future<Response<TResponse>> patch<TResponse>(
    String path, {
    Object? data,
  }) =>
      _execute(() => _dio.patch<TResponse>(path, data: data));

  Future<Response<TResponse>> delete<TResponse>(
    String path, {
    Object? data,
  }) =>
      _execute(() => _dio.delete<TResponse>(path, data: data));

  // ---------------------------------------------------------------------------
  // Execution wrapper — maps DioException to AppException
  // ---------------------------------------------------------------------------

  Future<Response<TResponse>> _execute<TResponse>(
    Future<Response<TResponse>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (dioError) {
      throw NetworkExceptionHandler.mapDioException(dioError);
    }
  }

  // ---------------------------------------------------------------------------
  // Factory
  // ---------------------------------------------------------------------------

  static Dio _createDio({
    required SecureStorage secureStorage,
    required OnSessionExpired onSessionExpired,
    OnTokenRefreshed? onTokenRefreshed,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Order matters: logging first (sees raw request), auth second (attaches
    // token), token refresh last (handles 401 after auth has run).
    dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(secureStorage: secureStorage),
      TokenRefreshInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        onSessionExpired: onSessionExpired,
        onTokenRefreshed: onTokenRefreshed,
      ),
    ]);

    return dio;
  }
}
