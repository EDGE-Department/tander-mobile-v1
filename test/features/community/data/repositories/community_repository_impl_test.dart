import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/features/community/data/datasources/community_remote_datasource.dart';
import 'package:tander_flutter_v3/features/community/data/repositories/community_repository_impl.dart';

// Community responses are BARE DTO JSON — no {success,data} wrapper.
// Photos/photoUrl omitted so resolvePhotoUrl(null) short-circuits (no
// Platform/EnvConfig coupling).

Map<String, Object?> _postJson({
  String id = 'p1',
  String? displayName,
  String content = 'hello world',
}) => {
  'id': id,
  'author': {'userId': 'u1', 'displayName': ?displayName},
  'content': content,
  'reactionCount': 3,
  'commentCount': 1,
  'hasReacted': false,
  'createdAt': '2026-05-28T08:00:00Z',
};

Map<String, Object?> _commentJson({
  String id = 'cm1',
  String? parentCommentId,
}) => {
  'id': id,
  'postId': 'p1',
  'author': {'userId': 'u1', 'displayName': 'Lola'},
  'content': 'nice post',
  'parentCommentId': ?parentCommentId,
  'createdAt': '2026-05-28T08:30:00Z',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late CommunityRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repository = CommunityRepositoryImpl(
      remoteDatasource: CommunityRemoteDatasource(
        dioClient: DioClient.withDio(dio),
      ),
    );
  });

  group('fetchFeed', () {
    test('maps a bare {posts, hasMore} body into a feed page', () async {
      adapter.onGet(
        '/api/community/feed',
        (server) => server.reply(200, {
          'posts': [_postJson(id: 'p1'), _postJson(id: 'p2')],
          'hasMore': true,
          'nextCursor': 'cur-2',
        }),
      );

      final result = await repository.fetchFeed();

      expect(result.isSuccess, isTrue);
      final page = result.valueOrNull!;
      expect(page.posts, hasLength(2));
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'cur-2');
      expect(page.posts.first.reactionCount, 3);
      expect(page.posts.first.createdAt, DateTime.utc(2026, 5, 28, 8));
    });

    test('maps a 500 to Failure(ServerException)', () async {
      adapter.onGet(
        '/api/community/feed',
        (server) => server.reply(500, {'message': 'down'}),
      );

      final result = await repository.fetchFeed();
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<ServerException>());
    });
  });

  group('fetchPost', () {
    test('maps a bare post DTO and applies the author fallback', () async {
      adapter.onGet(
        '/api/community/posts/p1',
        (server) => server.reply(200, _postJson(id: 'p1')),
      );

      final result = await repository.fetchPost(postId: 'p1');

      expect(result.isSuccess, isTrue);
      final post = result.valueOrNull!;
      expect(post.postId, 'p1');
      expect(post.content, 'hello world');
      // displayName absent → 'Tander User' fallback.
      expect(post.author.displayName, 'Tander User');
      expect(post.mediaUrls, isEmpty);
    });
  });

  group('updatePost', () {
    test('is a PATCH and returns the updated post', () async {
      adapter.onPatch(
        '/api/community/posts/p1',
        (server) => server.reply(
          200,
          _postJson(id: 'p1', content: 'edited'),
        ),
        data: Matchers.any,
      );

      final result = await repository.updatePost(postId: 'p1', content: 'edited');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.content, 'edited');
    });
  });

  group('fetchComments', () {
    test('maps a bare {comments, hasMore} body', () async {
      adapter.onGet(
        '/api/community/posts/p1/comments',
        (server) => server.reply(200, {
          'comments': [_commentJson(id: 'cm1')],
          'hasMore': false,
        }),
      );

      final result = await repository.fetchComments(postId: 'p1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.comments.single.body, 'nice post');
    });
  });

  group('createComment', () {
    test('top-level comment → mapped parentCommentId is null', () async {
      adapter.onPost(
        '/api/community/posts/p1/comments',
        (server) => server.reply(200, _commentJson(id: 'cm1')),
        data: Matchers.any,
      );

      final result = await repository.createComment(
        postId: 'p1',
        content: 'nice post',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.parentCommentId, isNull);
    });

    test('threaded reply → parentCommentId is carried through', () async {
      adapter.onPost(
        '/api/community/posts/p1/comments',
        (server) => server.reply(
          200,
          _commentJson(id: 'cm2', parentCommentId: 'cm1'),
        ),
        data: Matchers.any,
      );

      final result = await repository.createComment(
        postId: 'p1',
        content: 'replying',
        parentCommentId: 'cm1',
      );
      expect(result.valueOrNull!.parentCommentId, 'cm1');
    });
  });

  group('mutations with no body', () {
    test('toggleReaction succeeds on a 200 POST', () async {
      adapter.onPost(
        '/api/community/posts/p1/reactions',
        (server) => server.reply(200, {'ok': true}),
      );

      final result = await repository.toggleReaction(postId: 'p1');
      expect(result.isSuccess, isTrue);
    });

    test('deletePost succeeds on a 200 DELETE', () async {
      adapter.onDelete(
        '/api/community/posts/p1',
        (server) => server.reply(200, {'ok': true}),
      );

      final result = await repository.deletePost(postId: 'p1');
      expect(result.isSuccess, isTrue);
    });
  });
}
