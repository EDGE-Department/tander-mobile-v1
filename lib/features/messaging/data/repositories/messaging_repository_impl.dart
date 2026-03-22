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
      final rawList = response.data ?? <Object?>[];

      final conversations = rawList
          .whereType<Map<String, Object?>>()
          .map((json) => MessagingMapper.mapConversationDto(
                ConversationDto.fromJson(json),
                currentUserId: currentUserId,
              ))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return conversations;
    });
  }

  // -----------------------------------------------------------------------
  // Messages
  // -----------------------------------------------------------------------

  @override
  Future<Result<List<MessageItem>>> fetchMessages({
    required int conversationId,
  }) {
    return _runSafe('fetchMessages', () async {
      final response = await _remoteDatasource.fetchMessages(
        conversationId: conversationId,
      );
      final rawList = response.data ?? <Object?>[];

      final messages = rawList
          .whereType<Map<String, Object?>>()
          .map((json) => MessagingMapper.mapMessageDto(
                MessageDto.fromJson(json),
              ))
          .toList();

      return messages;
    });
  }

  @override
  Future<Result<MessageItem>> sendTextMessage({
    required int receiverId,
    required String content,
  }) {
    return _runSafe('sendTextMessage', () async {
      final response = await _remoteDatasource.sendTextMessage(
        receiverId: receiverId,
        content: content,
      );
      final body = _requireResponseBody(response.data, 'send text message');
      return MessagingMapper.mapMessageDto(MessageDto.fromJson(body));
    });
  }

  @override
  Future<Result<MessageItem>> sendImageMessage({
    required String roomId,
    required String filePath,
    required String fileName,
  }) {
    return _runSafe('sendImageMessage', () async {
      final response = await _remoteDatasource.sendImageMessage(
        roomId: roomId,
        filePath: filePath,
        fileName: fileName,
      );
      final body = _requireResponseBody(response.data, 'send image message');
      return MessagingMapper.mapMessageDto(MessageDto.fromJson(body));
    });
  }

  @override
  Future<Result<MessageItem>> sendVoiceMessage({
    required String roomId,
    required String filePath,
    required String fileName,
    required int durationSeconds,
  }) {
    return _runSafe('sendVoiceMessage', () async {
      final response = await _remoteDatasource.sendVoiceMessage(
        roomId: roomId,
        filePath: filePath,
        fileName: fileName,
        durationSeconds: durationSeconds,
      );
      final body = _requireResponseBody(response.data, 'send voice message');
      return MessagingMapper.mapMessageDto(MessageDto.fromJson(body));
    });
  }

  @override
  Future<Result<void>> markConversationRead({
    required int conversationId,
  }) {
    return _runSafe('markConversationRead', () async {
      await _remoteDatasource.markConversationRead(
        conversationId: conversationId,
      );
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
      throw FormatException(
        'Empty response body from $endpointLabel endpoint',
      );
    }
    return body;
  }
}
