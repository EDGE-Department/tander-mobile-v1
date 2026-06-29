import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// Regression guard for the age-verification dead-end.
///
/// The trap: the client hardcoded a minimum age of 60 while the backend's
/// min-age is dynamically configurable (set to 20 in prod for testing). Users
/// aged 20-59 cleared the backend ID gate, created an account, then got stuck
/// at profile setup because the client re-gated their (locked) DOB against 60.
///
/// The fix sources the minimum age from the backend via
/// `GET /auth/verification-config` (behind `minimumAgeProvider`). These tests
/// lock in that the parsed value is the backend's, and — critically — that an
/// unusable response resolves to `null` ("unknown") rather than a restrictive
/// default. `null` is what lets callers FAIL OPEN instead of re-creating the
/// trap; returning a hardcoded 60 here is exactly the bug we removed.
void main() {
  late Dio dio;
  late DioAdapter adapter;
  late AuthRemoteDatasource datasource;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    datasource = AuthRemoteDatasource(dioClient: DioClient.withDio(dio));
  });

  group('AuthRemoteDatasource.getMinimumAge', () {
    test(
      'returns the backend minimum age (20), not a hardcoded default',
      () async {
        adapter.onGet(
          ApiEndpoints.verificationConfig,
          (server) => server.reply(200, {
            'data': {'minimumAge': 20},
          }),
        );

        expect(await datasource.getMinimumAge(), 20);
      },
    );

    test('coerces a numeric (non-int) minimumAge to an int', () async {
      adapter.onGet(
        ApiEndpoints.verificationConfig,
        (server) => server.reply(200, {
          'data': {'minimumAge': 21.0},
        }),
      );

      expect(await datasource.getMinimumAge(), 21);
    });

    test('returns null (unknown) when the data envelope is missing', () async {
      adapter.onGet(
        ApiEndpoints.verificationConfig,
        (server) => server.reply(200, {'unexpected': true}),
      );

      expect(await datasource.getMinimumAge(), isNull);
    });

    test(
      'returns null (unknown) when minimumAge is absent from data',
      () async {
        adapter.onGet(
          ApiEndpoints.verificationConfig,
          (server) => server.reply(200, {
            'data': {'somethingElse': 1},
          }),
        );

        expect(await datasource.getMinimumAge(), isNull);
      },
    );
  });
}
