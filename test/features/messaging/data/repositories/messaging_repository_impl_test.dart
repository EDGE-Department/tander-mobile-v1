import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:tander_flutter_v3/features/messaging/data/repositories/messaging_repository_impl.dart';

Map<String, Object?> _convoJson({
  required String id,
  required String lastMessageAt,
  String otherUserId = 'u2',
}) => {
  'id': id,
  'otherUserId': otherUserId,
  'lastMessageAt': lastMessageAt,
  'lastMessageBody': 'hi',
};

Map<String, Object?> _msgJson({
  required String id,
  required String sentAt,
  String conversationId = 'c1',
}) => {
  'id': id,
  'conversationId': conversationId,
  'senderUserId': 'u2',
  'kind': 'TEXT',
  'sentAt': sentAt,
  'body': 'hi',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late MessagingRepositoryImpl repository;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repository = MessagingRepositoryImpl(
      remoteDatasource: MessagingRemoteDatasource(
        dioClient: DioClient.withDio(dio),
      ),
    );
  });

  group('fetchConversations', () {
    test('unwraps {data:[...]} and sorts by updatedAt DESC', () async {
      // Supplied oldest-first so the DESC sort must reorder them.
      adapter.onGet(
        '/chat/conversations',
        (server) => server.reply(200, {
          'data': [
            _convoJson(id: 'old', lastMessageAt: '2026-05-28T08:00:00Z'),
            _convoJson(id: 'new', lastMessageAt: '2026-05-28T10:00:00Z'),
          ],
        }),
      );

      final result = await repository.fetchConversations(currentUserId: 'me');

      expect(result.isSuccess, isTrue);
      final items = result.valueOrNull!;
      expect(items, hasLength(2));
      expect(items.first.conversationId, 'new'); // newest first
      expect(items.last.conversationId, 'old');
    });

    test('returns an empty list when the body has no data key', () async {
      // Pinned landmine: _unwrapListResponse silently returns [] (no throw)
      // when `data` is absent. A contract change would show "no chats", not error.
      adapter.onGet(
        '/chat/conversations',
        (server) => server.reply(200, {}),
      );

      final result = await repository.fetchConversations(currentUserId: 'me');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('maps a 500 to Failure(ServerException)', () async {
      adapter.onGet(
        '/chat/conversations',
        (server) => server.reply(500, {'message': 'down'}),
      );

      final result = await repository.fetchConversations(currentUserId: 'me');
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<ServerException>());
    });
  });

  group('fetchMessages', () {
    test('unwraps {data:[...]} and sorts by sentAt ASC', () async {
      // Supplied newest-first so the ASC sort must reorder them.
      adapter.onGet(
        '/chat/conversations/c1/messages',
        (server) => server.reply(200, {
          'data': [
            _msgJson(id: 'later', sentAt: '2026-05-28T10:00:00Z'),
            _msgJson(id: 'earlier', sentAt: '2026-05-28T08:00:00Z'),
          ],
        }),
      );

      final result = await repository.fetchMessages(conversationId: 'c1');

      expect(result.isSuccess, isTrue);
      final items = result.valueOrNull!;
      expect(items.first.messageId, 'earlier'); // oldest first
      expect(items.last.messageId, 'later');
    });
  });

  group('sendTextMessage', () {
    test('maps the flat response body into a MessageItem', () async {
      adapter.onPost(
        '/chat/conversations/c1/messages',
        (server) => server.reply(
          200,
          _msgJson(id: 'm-new', sentAt: '2026-05-28T11:00:00Z'),
        ),
        data: Matchers.any,
      );

      final result = await repository.sendTextMessage(
        conversationId: 'c1',
        body: 'hello',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.messageId, 'm-new');
    });
  });

  group('startConversation', () {
    test('is a GET and maps the conversation body', () async {
      adapter.onGet(
        '/chat/users/u2/start-conversation',
        (server) => server.reply(
          200,
          _convoJson(id: 'c-new', lastMessageAt: '2026-05-28T09:00:00Z'),
        ),
      );

      final result = await repository.startConversation(
        otherUserId: 'u2',
        currentUserId: 'me',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.conversationId, 'c-new');
    });
  });

  group('markConversationRead', () {
    test('succeeds on a 200 POST with no body', () async {
      adapter.onPost(
        '/chat/conversations/c1/read',
        (server) => server.reply(200, {'ok': true}),
      );

      final result = await repository.markConversationRead(conversationId: 'c1');
      expect(result.isSuccess, isTrue);
    });
  });
}
