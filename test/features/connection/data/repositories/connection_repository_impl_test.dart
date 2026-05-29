import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/features/connection/data/datasources/connection_remote_datasource.dart';
import 'package:tander_flutter_v3/features/connection/data/repositories/connection_repository_impl.dart';

/// A match JSON. Uses a full https photo URL so resolvePhotoUrl is a no-op
/// (avoids the Platform.isAndroid / EnvConfig coupling).
Map<String, Object?> _matchJson({
  String id = 'match-1',
  String otherUserId = 'u2',
  String status = 'PENDING',
  String? otherUsername = 'bob',
  String? otherDisplayName,
  int? otherAge = 65,
}) => {
  'id': id,
  'otherUserId': otherUserId,
  'status': status,
  'otherUsername': otherUsername,
  'otherDisplayName': ?otherDisplayName,
  'otherProfilePhotoUrl': 'https://cdn/$otherUserId.jpg',
  'otherAge': otherAge,
  'matchedAt': '2026-05-28T08:00:00Z',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ConnectionRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repository = ConnectionRepositoryImpl(
      remoteDatasource: ConnectionRemoteDatasource(
        dioClient: DioClient.withDio(dio),
      ),
      currentUserId: 'me',
    );
  });

  group('fetchIncomingRequests', () {
    test('parses a direct list and stamps pendingIncoming state', () async {
      adapter.onGet(
        '/api/matches/received',
        (server) => server.reply(200, [
          _matchJson(id: 'm1', otherDisplayName: 'Bob Santos'),
          _matchJson(id: 'm2'),
        ]),
      );

      final result = await repository.fetchIncomingRequests();

      expect(result.isSuccess, isTrue);
      final page = result.valueOrNull!;
      expect(page.items, hasLength(2));
      expect(page.totalCount, 2);
      expect(page.pageSize, 2);
      expect(page.currentPage, 0);
      expect(page.hasNextPage, isFalse);
      // expectedState overrides DTO status.
      expect(
        page.items.first.relationshipState,
        ConnectionRelationshipState.pendingIncoming,
      );
      // displayName preferred over username.
      expect(page.items.first.otherUsername, 'Bob Santos');
      expect(page.items[1].otherUsername, 'bob');
    });

    test('unwraps a {success, data: [...]} envelope', () async {
      adapter.onGet(
        '/api/matches/received',
        (server) => server.reply(200, {
          'success': true,
          'data': [_matchJson(id: 'm1')],
        }),
      );

      final result = await repository.fetchIncomingRequests();
      expect(result.valueOrNull!.items, hasLength(1));
    });

    test('returns an empty page when the body has no usable list', () async {
      adapter.onGet(
        '/api/matches/received',
        (server) => server.reply(200, {'unexpected': true}),
      );

      final result = await repository.fetchIncomingRequests();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.items, isEmpty);
      expect(result.valueOrNull!.totalCount, 0);
    });

    test('maps a 500 to Failure(ServerException)', () async {
      adapter.onGet(
        '/api/matches/received',
        (server) => server.reply(500, {'message': 'down'}),
      );

      final result = await repository.fetchIncomingRequests();
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<ServerException>());
    });
  });

  group('fetchConnections', () {
    test('parses a Spring {content: [...]} envelope as connected', () async {
      adapter.onGet(
        '/api/matches/connected',
        (server) => server.reply(200, {
          'content': [_matchJson(id: 'm1', status: 'ACCEPTED')],
          'number': 0,
          'last': true,
        }),
      );

      final result = await repository.fetchConnections();
      expect(result.valueOrNull!.items.single.relationshipState,
          ConnectionRelationshipState.connected);
    });
  });

  group('fetchBlockedUsers', () {
    test('derives state from DTO status when no expectedState given', () async {
      // No expectedState → _computeRelationshipState: BLOCKED → none.
      adapter.onGet(
        '/api/matches/blocked',
        (server) => server.reply(200, [_matchJson(id: 'm1', status: 'BLOCKED')]),
      );

      final result = await repository.fetchBlockedUsers();
      expect(result.valueOrNull!.items.single.relationshipState,
          ConnectionRelationshipState.none);
    });
  });

  group('mutations', () {
    test('acceptRequest succeeds on a 200 POST', () async {
      adapter.onPost(
        '/api/matches/m1/accept',
        (server) => server.reply(200, {'ok': true}),
      );

      final result = await repository.acceptRequest(matchId: 'm1');
      expect(result.isSuccess, isTrue);
    });

    test('cancelRequest succeeds on a 200 DELETE', () async {
      adapter.onDelete(
        '/api/matches/m1/cancel',
        (server) => server.reply(200, null),
      );

      final result = await repository.cancelRequest(matchId: 'm1');
      expect(result.isSuccess, isTrue);
    });

    test('acceptRequest maps a 404 to Failure(NotFoundException)', () async {
      adapter.onPost(
        '/api/matches/m1/accept',
        (server) => server.reply(404, {'message': 'gone'}),
      );

      final result = await repository.acceptRequest(matchId: 'm1');
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotFoundException>());
    });
  });
}
