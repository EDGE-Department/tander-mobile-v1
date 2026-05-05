import 'package:tander_flutter_v3/core/contracts/messaging_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/mappers/messaging_mapper.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:tander_flutter_v3/features/messaging/domain/repositories/messaging_repository.dart';

/// Coordinates [MessagingRemoteDatasource] to fulfil the
/// [MessagingRepository] contract.
///
/// Every public method catches all exceptions and wraps them in
/// [Failure] so callers never see raw throws.
final class MessagingRepositoryImpl implements MessagingRepository {
  const MessagingRepositoryImpl({
    required MessagingRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final MessagingRemoteDatasource _remoteDatasource;

  static const String _tag = 'MessagingRepositoryImpl';

  // -----------------------------------------------------------------------
  // Conversations
  // -----------------------------------------------------------------------

  @override
  Future<Result<List<ConversationItem>>> fetchConversations({
    required String currentUserId,
  }) {
    return _runSafe('fetchConversations', () async {
      final response = await _remoteDatasource.fetchConversations();
      final rawList = _unwrapListResponse(response.data);

      final conversations =
          rawList
              .whereType<Map<String, Object?>>()
              .map(
                (json) => MessagingMapper.mapConversationDto(
                  ConversationDto.fromJson(json),
                  currentUserId: currentUserId,
                ),
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return conversations;
    });
  }

  @override
  Future<Result<ConversationItem>> startConversation({
    required String otherUserId,
    required String currentUserId,
  }) {
    return _runSafe('startConversation', () async {
      final response = await _remoteDatasource.startConversation(
        otherUserId: otherUserId,
      );
      final body = _requireResponseBody(response.data, 'start conversation');
      final unwrapped = _unwrapResponse(body);
      return MessagingMapper.mapConversationDto(
        ConversationDto.fromJson(unwrapped),
        currentUserId: currentUserId,
      );
    });
  }

  // -----------------------------------------------------------------------
  // Messages
  // -----------------------------------------------------------------------

  @override
  Future<Result<List<MessageItem>>> fetchMessages({
    required String conversationId,
  }) {
    return _runSafe('fetchMessages', () async {
      final response = await _remoteDatasource.fetchMessages(
        conversationId: conversationId,
      );
      final rawList = _unwrapListResponse(response.data);

      final messages =
          rawList
              .whereType<Map<String, Object?>>()
              .map(
                (json) =>
                    MessagingMapper.mapMessageDto(MessageDto.fromJson(json)),
              )
              .toList()
            ..sort((a, b) => a.sentAt.compareTo(b.sentAt)); // oldest first

      return messages;
    });
  }

  @override
  Future<Result<MessageItem>> sendTextMessage({
    required String conversationId,
    required String body,
  }) {
    return _runSafe('sendTextMessage', () async {
      final response = await _remoteDatasource.sendTextMessage(
        conversationId: conversationId,
        body: body,
      );
      final responseBody = _requireResponseBody(
        response.data,
        'send text message',
      );
      final unwrapped = _unwrapResponse(responseBody);
      return MessagingMapper.mapMessageDto(MessageDto.fromJson(unwrapped));
    });
  }

  @override
  Future<Result<MessageItem>> sendImageMessage({
    required String conversationId,
    required String filePath,
    required String fileName,
  }) {
    return _runSafe('sendImageMessage', () async {
      final response = await _remoteDatasource.sendImageMessage(
        roomId: conversationId,
        filePath: filePath,
        fileName: fileName,
      );
      final body = _requireResponseBody(response.data, 'send image message');
      final unwrapped = _unwrapResponse(body);
      return MessagingMapper.mapMessageDto(MessageDto.fromJson(unwrapped));
    });
  }

  @override
  Future<Result<MessageItem>> sendVoiceMessage({
    required String conversationId,
    required String filePath,
    required String fileName,
    required int durationSeconds,
  }) {
    return _runSafe('sendVoiceMessage', () async {
      final response = await _remoteDatasource.sendVoiceMessage(
        roomId: conversationId,
        filePath: filePath,
        fileName: fileName,
        durationSeconds: durationSeconds,
      );
      final body = _requireResponseBody(response.data, 'send voice message');
      final unwrapped = _unwrapResponse(body);
      return MessagingMapper.mapMessageDto(MessageDto.fromJson(unwrapped));
    });
  }

  @override
  Future<Result<void>> markConversationRead({required String conversationId}) {
    return _runSafe('markConversationRead', () async {
      await _remoteDatasource.markConversationRead(
        conversationId: conversationId,
      );
    });
  }

  @override
  Future<Result<void>> unsendMessage({required String messageId}) {
    return _runSafe('unsendMessage', () async {
      await _remoteDatasource.unsendMessage(messageId: messageId);
    });
  }

  @override
  Future<Result<void>> hideMessageForUser({required String messageId}) {
    return _runSafe('hideMessageForUser', () async {
      await _remoteDatasource.hideMessageForUser(messageId: messageId);
    });
  }

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  Future<Result<TValue>> _runSafe<TValue>(
    String operationName,
    Future<TValue> Function() action,
  ) async {
    try {
      final value = await action();
      return Success(value);
    } on AppException catch (exception) {
      return Failure(exception);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        '$operationName failed',
        operation: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      return Failure(
        UnknownException(
          message: '$operationName failed: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Map<String, Object?> _requireResponseBody(
    Map<String, Object?>? body,
    String endpointLabel,
  ) {
    if (body == null) {
      throw FormatException('Empty response body from $endpointLabel endpoint');
    }
    return body;
  }

  /// Unwraps the backend's `{success, data}` wrapper and extracts the list.
  /// Handles both direct list and paginated `{ items: [...] }` formats.
  List<Object?> _unwrapListResponse(Map<String, Object?>? body) {
    if (body == null) return <Object?>[];
    final data = body['data'];
    // Direct list format: { data: [...] }
    if (data is List<Object?>) return data;
    // Paginated format: { data: { items: [...] } }
    if (data is Map<String, Object?>) {
      final items = data['items'];
      if (items is List<Object?>) return items;
      // Also handle 'content' for Spring pagination
      final content = data['content'];
      if (content is List<Object?>) return content;
    }
    return <Object?>[];
  }

  /// Unwraps the backend's standard `{success, data}` wrapper.
  /// If the response is already unwrapped (no `data` key), returns as-is.
  Map<String, Object?> _unwrapResponse(Map<String, Object?> body) {
    if (body.containsKey('data') && body['data'] is Map<String, Object?>) {
      return body['data'] as Map<String, Object?>;
    }
    return body;
  }
}
