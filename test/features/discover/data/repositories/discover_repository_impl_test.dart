import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:tander_flutter_v3/features/discover/data/repositories/discover_repository_impl.dart';

/// A discovery profile JSON with all required `is*` bools present.
Map<String, Object?> _profileJson({
  String userId = 'u1',
  String username = 'alice',
  String? displayName,
  List<String>? additionalPhotos,
}) => {
  'userId': userId,
  'username': username,
  'displayName': ?displayName,
  'profilePhotoUrl': 'https://cdn/$userId.jpg',
  'additionalPhotos': ?additionalPhotos,
  'interests': const ['reading'],
  'verified': true,
  'online': true,
  'hasBeenSwiped': false,
  'hasLikedMe': false,
  'matched': false,
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late DiscoverRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repository = DiscoverRepositoryImpl(
      remoteDatasource: DiscoverRemoteDatasource(
        dioClient: DioClient.withDio(dio),
      ),
    );
  });

  group('fetchProfiles', () {
    test('maps a Spring page envelope into PaginatedCandidates', () async {
      adapter.onGet(
        '/api/discovery/profiles',
        (server) => server.reply(200, {
          'content': [
            _profileJson(userId: 'u1', displayName: 'ROBERTO TUBIG DREZ'),
            _profileJson(userId: 'u2', username: 'bob'),
          ],
          'number': 0,
          'totalPages': 3,
          'totalElements': 50,
          'last': false,
        }),
      );

      final result = await repository.fetchProfiles();

      expect(result.isSuccess, isTrue);
      final page = result.valueOrNull!;
      expect(page.candidates, hasLength(2));
      expect(page.currentPage, 0);
      expect(page.totalPages, 3);
      expect(page.totalElements, 50);
      expect(page.isLastPage, isFalse);
      // firstName is derived from displayName's first token.
      expect(page.candidates.first.firstName, 'ROBERTO');
      // Falls back to username when displayName is absent.
      expect(page.candidates[1].firstName, 'bob');
    });

    test('tolerates a missing/non-list content field', () async {
      adapter.onGet(
        '/api/discovery/profiles',
        (server) => server.reply(200, {'number': 0, 'last': true}),
      );

      final result = await repository.fetchProfiles();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.candidates, isEmpty);
      expect(result.valueOrNull!.isLastPage, isTrue);
    });

    test('maps a 500 to Failure(ServerException)', () async {
      adapter.onGet(
        '/api/discovery/profiles',
        (server) => server.reply(500, {'message': 'down'}),
      );

      final result = await repository.fetchProfiles();
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<ServerException>());
    });
  });

  group('fetchProfile', () {
    test('maps a single profile, resolving fields', () async {
      adapter.onGet(
        '/api/discovery/profile/u9',
        (server) => server.reply(
          200,
          _profileJson(
            userId: 'u9',
            displayName: 'Maria Clara',
            additionalPhotos: const ['https://cdn/a.jpg', 'https://cdn/b.jpg'],
          ),
        ),
      );

      final result = await repository.fetchProfile(userId: 'u9');

      expect(result.isSuccess, isTrue);
      final candidate = result.valueOrNull!;
      expect(candidate.userId, 'u9');
      expect(candidate.firstName, 'Maria');
      expect(candidate.profilePhotoUrl, 'https://cdn/u9.jpg');
      expect(candidate.additionalPhotos, hasLength(2));
      expect(candidate.isOnline, isTrue);
    });

    test('unwraps a {success, data} envelope', () async {
      adapter.onGet(
        '/api/discovery/profile/u9',
        (server) => server.reply(200, {
          'success': true,
          'data': _profileJson(userId: 'u9', username: 'zoe'),
        }),
      );

      final result = await repository.fetchProfile(userId: 'u9');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.firstName, 'zoe');
    });
  });

  group('swipe actions', () {
    test('sendConnectionRequest succeeds on 200', () async {
      adapter.onPost(
        '/api/matches/swipe',
        (server) => server.reply(200, {'matched': false}),
        data: Matchers.any,
      );

      final result = await repository.sendConnectionRequest(targetUserId: 'u2');
      expect(result.isSuccess, isTrue);
    });

    test('passOnProfile succeeds on 200', () async {
      adapter.onPost(
        '/api/matches/swipe',
        (server) => server.reply(200, {'matched': false}),
        data: Matchers.any,
      );

      final result = await repository.passOnProfile(targetUserId: 'u2');
      expect(result.isSuccess, isTrue);
    });

    test('maps a 409 conflict to Failure(ConflictException)', () async {
      adapter.onPost(
        '/api/matches/swipe',
        (server) => server.reply(409, {'message': 'already swiped'}),
        data: Matchers.any,
      );

      final result = await repository.sendConnectionRequest(targetUserId: 'u2');
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<ConflictException>());
    });
  });
}
