import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/network/network_exception_handler.dart';

/// Builds a [DioException] with an HTTP response of [statusCode] and [data].
DioException _httpError(int statusCode, {Object? data}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: req,
      statusCode: statusCode,
      data: data,
    ),
  );
}

/// Builds a connection-level [DioException] (no HTTP response).
DioException _connectionError(DioExceptionType type) {
  return DioException(requestOptions: RequestOptions(path: '/x'), type: type);
}

void main() {
  group('NetworkExceptionHandler.mapDioException — connection failures', () {
    test('all transport error types map to NetworkException', () {
      for (final type in const [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          NetworkExceptionHandler.mapDioException(_connectionError(type)),
          isA<NetworkException>(),
          reason: '$type should be a NetworkException',
        );
      }
    });
  });

  group('NetworkExceptionHandler.mapDioException — no response', () {
    test('badResponse without a response object maps to UnknownException', () {
      final exc = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
      );
      expect(
        NetworkExceptionHandler.mapDioException(exc),
        isA<UnknownException>(),
      );
    });
  });

  group('NetworkExceptionHandler.mapDioException — status codes', () {
    test('400 → ValidationException with parsed fieldErrors', () {
      final result = NetworkExceptionHandler.mapDioException(
        _httpError(400, data: {
          'message': 'Validation failed',
          'fieldErrors': {
            'email': ['must not be blank', 'must be valid'],
            'age': ['must be >= 60'],
          },
        }),
      );

      expect(result, isA<ValidationException>());
      final validation = result as ValidationException;
      expect(validation.message, 'Validation failed');
      expect(validation.fieldErrors['email'], [
        'must not be blank',
        'must be valid',
      ]);
      expect(validation.fieldErrors['age'], ['must be >= 60']);
    });

    test('400 with malformed fieldErrors yields an empty error map', () {
      final result = NetworkExceptionHandler.mapDioException(
        _httpError(400, data: {'fieldErrors': 'not-a-map'}),
      );
      expect(result, isA<ValidationException>());
      expect((result as ValidationException).fieldErrors, isEmpty);
    });

    test('401 → AuthException, tokenExpired by default', () {
      final result = NetworkExceptionHandler.mapDioException(
        _httpError(401, data: {'message': 'expired'}),
      );
      expect(result, isA<AuthException>());
      expect(
        (result as AuthException).reason,
        AuthFailureReason.tokenExpired,
      );
    });

    test('401 with INVALID_CREDENTIALS code → invalidCredentials reason', () {
      final result = NetworkExceptionHandler.mapDioException(
        _httpError(401, data: {'code': 'INVALID_CREDENTIALS'}),
      );
      expect(
        (result as AuthException).reason,
        AuthFailureReason.invalidCredentials,
      );
    });

    test('403 → AuthException with forbidden reason', () {
      final result = NetworkExceptionHandler.mapDioException(_httpError(403));
      expect(result, isA<AuthException>());
      expect((result as AuthException).reason, AuthFailureReason.forbidden);
    });

    test('404 → NotFoundException', () {
      expect(
        NetworkExceptionHandler.mapDioException(_httpError(404)),
        isA<NotFoundException>(),
      );
    });

    test('409 → ConflictException', () {
      expect(
        NetworkExceptionHandler.mapDioException(_httpError(409)),
        isA<ConflictException>(),
      );
    });

    test('429 → RateLimitException, retryAfter from int', () {
      final result = NetworkExceptionHandler.mapDioException(
        _httpError(429, data: {'retryAfterSeconds': 120}),
      );
      expect(result, isA<RateLimitException>());
      expect((result as RateLimitException).retryAfterSeconds, 120);
    });

    test('429 retryAfter parses a numeric String', () {
      final result = NetworkExceptionHandler.mapDioException(
        _httpError(429, data: {'retryAfterSeconds': '45'}),
      );
      expect((result as RateLimitException).retryAfterSeconds, 45);
    });

    test('429 retryAfter defaults to 30 when absent', () {
      final result = NetworkExceptionHandler.mapDioException(_httpError(429));
      expect((result as RateLimitException).retryAfterSeconds, 30);
    });

    test('500 and 503 → ServerException carrying the status code', () {
      final five00 = NetworkExceptionHandler.mapDioException(_httpError(500));
      final five03 = NetworkExceptionHandler.mapDioException(_httpError(503));
      expect(five00, isA<ServerException>());
      expect((five00 as ServerException).statusCode, 500);
      expect((five03 as ServerException).statusCode, 503);
    });

    test('an unmapped 4xx (418) → UnknownException', () {
      expect(
        NetworkExceptionHandler.mapDioException(_httpError(418)),
        isA<UnknownException>(),
      );
    });

    test('server message is surfaced on the mapped exception', () {
      final result = NetworkExceptionHandler.mapDioException(
        _httpError(404, data: {'message': 'No such user'}),
      );
      expect(result.message, 'No such user');
    });
  });
}
