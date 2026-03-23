import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Maps [DioException] instances to typed [AppException] subclasses.
///
/// Call [mapDioException] at the repository / data-source boundary so that
/// domain and presentation layers never see Dio-specific types.
final class NetworkExceptionHandler {
  const NetworkExceptionHandler._();

  /// Converts a [DioException] into the appropriate [AppException] subtype.
  static AppException mapDioException(DioException exception) {
    AppLogger.error(
      'Network error: ${exception.message ?? exception.type.name}',
      operation: 'NetworkExceptionHandler',
      error: exception,
      stackTrace: exception.stackTrace,
    );

    // --- Connection-level failures (no HTTP response) ---
    if (_isConnectionFailure(exception.type)) {
      return NetworkException(
        message: exception.message ?? 'Connection failed',
        stackTrace: exception.stackTrace,
      );
    }

    // --- HTTP response failures ---
    final statusCode = exception.response?.statusCode;
    if (statusCode == null) {
      return UnknownException(
        message: exception.message ?? 'Unknown network error',
        stackTrace: exception.stackTrace,
      );
    }

    return _mapStatusCode(
      statusCode: statusCode,
      exception: exception,
    );
  }

  // ---------------------------------------------------------------------------
  // Status code mapping
  // ---------------------------------------------------------------------------

  static AppException _mapStatusCode({
    required int statusCode,
    required DioException exception,
  }) {
    final responseBody = _extractResponseBody(exception);

    return switch (statusCode) {
      400 => _buildValidationException(responseBody, exception),
      401 => AuthException(
          message: _extractMessage(responseBody) ??
              'Your session has expired. Please sign in again.',
          reason: _extractCode(responseBody) == 'INVALID_CREDENTIALS'
              ? AuthFailureReason.invalidCredentials
              : AuthFailureReason.tokenExpired,
          stackTrace: exception.stackTrace,
        ),
      403 => AuthException(
          message: _extractMessage(responseBody) ??
              'You do not have permission to perform this action.',
          reason: AuthFailureReason.forbidden,
          stackTrace: exception.stackTrace,
        ),
      404 => NotFoundException(
          message: _extractMessage(responseBody) ??
              'The requested resource was not found.',
          stackTrace: exception.stackTrace,
        ),
      409 => ConflictException(
          message: _extractMessage(responseBody) ??
              'A conflict occurred with your request.',
          stackTrace: exception.stackTrace,
        ),
      429 => RateLimitException(
          message: _extractMessage(responseBody) ??
              'Too many requests. Please wait and try again.',
          retryAfterSeconds: _extractRetryAfter(responseBody),
          stackTrace: exception.stackTrace,
        ),
      >= 500 => ServerException(
          message: _extractMessage(responseBody) ??
              'Something went wrong on our end.',
          statusCode: statusCode,
          stackTrace: exception.stackTrace,
        ),
      _ => UnknownException(
          message: _extractMessage(responseBody) ??
              'Unexpected HTTP $statusCode',
          stackTrace: exception.stackTrace,
        ),
    };
  }

  // ---------------------------------------------------------------------------
  // Validation exception builder
  // ---------------------------------------------------------------------------

  static ValidationException _buildValidationException(
    Map<String, Object?> responseBody,
    DioException exception,
  ) {
    final fieldErrors = _extractFieldErrors(responseBody);

    return ValidationException(
      message: _extractMessage(responseBody) ??
          'Please correct the highlighted fields.',
      fieldErrors: fieldErrors,
      stackTrace: exception.stackTrace,
    );
  }

  /// Parses `fieldErrors` from the response body.
  ///
  /// Expected backend shape:
  /// ```json
  /// { "fieldErrors": { "email": ["must not be blank"], "age": ["must be >= 60"] } }
  /// ```
  static Map<String, List<String>> _extractFieldErrors(
    Map<String, Object?> body,
  ) {
    final rawErrors = body['fieldErrors'];
    if (rawErrors is! Map<String, Object?>) {
      return const {};
    }

    final parsed = <String, List<String>>{};
    for (final entry in rawErrors.entries) {
      final rawMessages = entry.value;
      if (rawMessages is List<Object?>) {
        parsed[entry.key] = rawMessages
            .whereType<String>()
            .toList(growable: false);
      }
    }

    return parsed;
  }

  // ---------------------------------------------------------------------------
  // Response body extraction helpers
  // ---------------------------------------------------------------------------

  static Map<String, Object?> _extractResponseBody(DioException exception) {
    final responseData = exception.response?.data;
    if (responseData is Map<String, Object?>) return responseData;
    return const {};
  }

  static String? _extractMessage(Map<String, Object?> body) {
    final message = body['message'];
    return message is String && message.isNotEmpty ? message : null;
  }

  static String? _extractCode(Map<String, Object?> body) {
    final code = body['code'];
    return code is String && code.isNotEmpty ? code : null;
  }

  static int _extractRetryAfter(Map<String, Object?> body) {
    final retryAfter = body['retryAfterSeconds'];
    if (retryAfter is int) return retryAfter;
    if (retryAfter is String) return int.tryParse(retryAfter) ?? 30;
    return 30;
  }

  // ---------------------------------------------------------------------------
  // Connection failure detection
  // ---------------------------------------------------------------------------

  static bool _isConnectionFailure(DioExceptionType type) => switch (type) {
        DioExceptionType.connectionTimeout => true,
        DioExceptionType.receiveTimeout => true,
        DioExceptionType.sendTimeout => true,
        DioExceptionType.connectionError => true,
        _ => false,
      };
}
