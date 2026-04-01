import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/core/contracts/tandy_contracts.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/mappers/tandy_mapper.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/tandy/data/datasources/tandy_remote_datasource.dart';
import 'package:tander_flutter_v3/features/tandy/domain/repositories/tandy_repository.dart';

/// Default greeting suggestions when the server returns just a string.
const List<String> _defaultGreetingSuggestions = <String>[
  "I'm feeling a bit down today",
  'Help me breathe and relax',
  "Let's talk about my day",
  'I need some encouragement',
];

/// Coordinates [TandyRemoteDatasource] to fulfil the
/// [TandyRepository] contract.
///
/// Every public method catches all exceptions and wraps them in
/// [Failure] so callers never see raw throws.
final class TandyRepositoryImpl implements TandyRepository {
  const TandyRepositoryImpl({
    required TandyRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final TandyRemoteDatasource _remoteDatasource;

  static const String _tag = 'TandyRepositoryImpl';

  // -----------------------------------------------------------------------
  // Conversation
  // -----------------------------------------------------------------------

  @override
  Future<Result<TandyThread>> fetchConversation() {
    return _runSafe('fetchConversation', () async {
      final response = await _remoteDatasource.fetchConversation();
      final body = _requireResponseBody(response.data, 'tandy conversation');
      final dto = TandyConversationDto.fromJson(body);
      return mapTandyConversationDto(dto);
    });
  }

  @override
  Future<Result<TandyGreeting>> fetchGreeting() {
    return _runSafe('fetchGreeting', () async {
      final response = await _remoteDatasource.fetchGreeting();
      final greetingText =
          response.data is String ? response.data as String : 'How are you feeling today?';
      return buildTandyGreeting(greetingText, _defaultGreetingSuggestions);
    });
  }

  // -----------------------------------------------------------------------
  // Send
  // -----------------------------------------------------------------------

  @override
  Future<Result<TandySendResult>> sendMessage({
    required String message,
    String? language,
  }) {
    return _runSafe('sendMessage', () async {
      final response = await _remoteDatasource.sendMessage(
        message: message,
        language: language,
      );
      final body = _requireResponseBody(response.data, 'tandy send');
      final dto = TandySendMessageResponseDto.fromJson(body);

      if (!dto.success) {
        throw ServerException(
          message: dto.error ?? 'Tandy is temporarily unavailable',
          statusCode: 200,
        );
      }

      return mapSendMessageResponse(dto);
    });
  }

  // -----------------------------------------------------------------------
  // Management
  // -----------------------------------------------------------------------

  @override
  Future<Result<void>> clearConversation() {
    return _runSafe('clearConversation', () async {
      await _remoteDatasource.clearConversation();
    });
  }

  @override
  Future<Result<void>> setLanguage({required String language}) {
    return _runSafe('setLanguage', () async {
      await _remoteDatasource.setLanguage(language: language);
    });
  }

  @override
  Future<Result<void>> expandCard({
    required int messageId,
    required bool isExpanded,
  }) {
    return _runSafe('expandCard', () async {
      await _remoteDatasource.expandCard(
        messageId: messageId,
        isExpanded: isExpanded,
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
