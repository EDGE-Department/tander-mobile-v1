import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

void main() {
  const exception = NetworkException(message: 'offline');

  group('Success', () {
    const result = Success<int>(7);

    test('reports success and exposes the value', () {
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.exceptionOrNull, isNull);
    });

    test('when() runs the success branch', () {
      final branch = result.when(
        success: (value) => 'ok:$value',
        failure: (_) => 'fail',
      );
      expect(branch, 'ok:7');
    });

    test('map() transforms the wrapped value', () {
      final mapped = result.map((value) => value * 2);
      expect(mapped, isA<Success<int>>());
      expect(mapped.valueOrNull, 14);
    });

    test('value equality', () {
      expect(const Success<int>(7), const Success<int>(7));
      expect(const Success<int>(7), isNot(const Success<int>(8)));
    });
  });

  group('Failure', () {
    const result = Failure<int>(exception);

    test('reports failure and exposes the exception', () {
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.exceptionOrNull, same(exception));
    });

    test('when() runs the failure branch', () {
      final branch = result.when(
        success: (_) => 'ok',
        failure: (e) => 'fail:${e.message}',
      );
      expect(branch, 'fail:offline');
    });

    test('map() preserves the failure and its exception', () {
      final mapped = result.map((value) => value.toString());
      expect(mapped, isA<Failure<String>>());
      expect(mapped.exceptionOrNull, same(exception));
    });

    test('exception equality', () {
      expect(const Failure<int>(exception), const Failure<int>(exception));
    });
  });
}
