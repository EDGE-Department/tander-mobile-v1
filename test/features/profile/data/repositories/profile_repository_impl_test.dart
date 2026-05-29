import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:tander_flutter_v3/features/profile/data/repositories/profile_repository_impl.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ProfileRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repository = ProfileRepositoryImpl(
      remoteDatasource: ProfileRemoteDatasource(
        dioClient: DioClient.withDio(dio),
      ),
    );
  });

  group('requestAccountDeletion', () {
    test('parses the 202 grace-window response into Success', () async {
      adapter.onPost(
        '/privacy/account-deletion',
        (server) => server.reply(202, {
          'id': 'del_1',
          'status': 'GRACE',
          'graceUntil': '2026-06-27T10:00:00Z',
        }),
        data: Matchers.any,
      );

      final result = await repository.requestAccountDeletion();

      expect(result.isSuccess, isTrue);
      final status = result.valueOrNull!;
      expect(status.id, 'del_1');
      expect(status.isPending, isTrue);
      expect(status.graceUntil, DateTime.utc(2026, 6, 27, 10));
    });

    test('maps a 500 server error to Failure(ServerException)', () async {
      adapter.onPost(
        '/privacy/account-deletion',
        (server) => server.reply(500, {'message': 'boom'}),
        data: Matchers.any,
      );

      final result = await repository.requestAccountDeletion();

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<ServerException>());
    });
  });

  group('cancelAccountDeletion', () {
    test('parses a CANCELLED response into Success (not pending)', () async {
      adapter.onPost(
        '/privacy/account-deletion/cancel',
        (server) => server.reply(200, {
          'id': 'del_1',
          'status': 'CANCELLED',
          'cancelledAt': '2026-05-28T11:00:00Z',
        }),
      );

      final result = await repository.cancelAccountDeletion();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, 'CANCELLED');
      expect(result.valueOrNull!.isPending, isFalse);
    });
  });

  group('fetchAccountDeletionStatus', () {
    test('returns Success(null) on 204 No Content', () async {
      adapter.onGet(
        '/privacy/account-deletion',
        (server) => server.reply(204, null),
      );

      final result = await repository.fetchAccountDeletionStatus();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('returns Success(status) on 200 with a body', () async {
      adapter.onGet(
        '/privacy/account-deletion',
        (server) => server.reply(200, {'id': 'del_9', 'status': 'GRACE'}),
      );

      final result = await repository.fetchAccountDeletionStatus();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNotNull);
      expect(result.valueOrNull!.isPending, isTrue);
    });
  });

  group('changePassword', () {
    test('returns Success on a 200 PATCH', () async {
      adapter.onPatch(
        '/user/change-password',
        (server) => server.reply(200, {'success': true}),
        data: Matchers.any,
      );

      final result = await repository.changePassword(
        oldPassword: 'old-pass-123',
        newPassword: 'new-pass-456',
      );

      expect(result.isSuccess, isTrue);
    });

    test(
      'maps a 401 (wrong current password) to Failure(AuthException)',
      () async {
        adapter.onPatch(
          '/user/change-password',
          (server) => server.reply(401, {
            'message': 'Current password is incorrect',
            'code': 'current-password-incorrect',
          }),
          data: Matchers.any,
        );

        final result = await repository.changePassword(
          oldPassword: 'wrong',
          newPassword: 'new-pass-456',
        );

        expect(result.isFailure, isTrue);
        expect(result.exceptionOrNull, isA<AuthException>());
      },
    );
  });

  group('requestDataExport', () {
    test('returns Success on a 202 POST', () async {
      adapter.onPost(
        '/privacy/export',
        (server) => server.reply(202, {'queued': true}),
      );

      final result = await repository.requestDataExport();

      expect(result.isSuccess, isTrue);
    });
  });
}
