import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Debug-only interceptor that logs HTTP request/response lifecycle.
///
/// Masks the `Authorization` header value to prevent token leaks in logs.
/// Only active when [kDebugMode] is true; in release builds every callback
/// is a no-op pass-through.
final class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final maskedHeaders = _maskSensitiveHeaders(options.headers);

      AppLogger.debug(
        '→ ${options.method} ${options.path}',
        operation: 'HTTP.request',
        context: {'headers': maskedHeaders.toString()},
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final requestStart = response.requestOptions.extra['_requestStartMs'];
      final elapsedMs = requestStart is int
          ? DateTime.now().millisecondsSinceEpoch - requestStart
          : null;

      AppLogger.debug(
        '← ${response.statusCode} ${response.requestOptions.path}'
        '${elapsedMs != null ? ' (${elapsedMs}ms)' : ''}',
        operation: 'HTTP.response',
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.warning(
        '✗ ${err.requestOptions.method} ${err.requestOptions.path} '
        '— ${err.message ?? err.type.name}',
        operation: 'HTTP.error',
        error: err,
      );
    }

    handler.next(err);
  }

  /// Returns a copy of [headers] with the `Authorization` value masked.
  Map<String, Object?> _maskSensitiveHeaders(Map<String, Object?> headers) {
    if (!headers.containsKey('Authorization')) return headers;

    return {...headers, 'Authorization': '***'};
  }
}
