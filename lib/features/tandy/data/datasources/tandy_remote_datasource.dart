import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/contracts/tandy_contracts.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// All Tandy-related API calls, delegating HTTP to [DioClient].
///
/// Returns raw [Response] objects so the repository layer can map DTOs
/// to domain models and wrap errors in [Result].
final class TandyRemoteDatasource {
  const TandyRemoteDatasource({required DioClient dioClient})
    : _dioClient = dioClient;

  final DioClient _dioClient;

  static const String _tag = 'TandyRemoteDatasource';

  // -----------------------------------------------------------------------
  // Conversation
  // -----------------------------------------------------------------------

  /// Fetches the current user's Tandy conversation thread.
  Future<Response<Map<String, Object?>>> fetchConversation() {
    AppLogger.debug(
      'Fetching Tandy conversation',
      operation: '$_tag.fetchConversation',
    );

    return _dioClient.get<Map<String, Object?>>(ApiEndpoints.tandyConversation);
  }

  /// Fetches the Tandy greeting message.
  Future<Response<Object?>> fetchGreeting() {
    AppLogger.debug(
      'Fetching Tandy greeting',
      operation: '$_tag.fetchGreeting',
    );

    return _dioClient.get<Object?>(ApiEndpoints.tandyGreeting);
  }

  // -----------------------------------------------------------------------
  // Send message
  // -----------------------------------------------------------------------

  /// Sends a message to Tandy and returns the full response including
  /// both user and assistant messages.
  Future<Response<Map<String, Object?>>> sendMessage({
    required String message,
    String? language,
  }) {
    AppLogger.debug(
      'Sending message to Tandy',
      operation: '$_tag.sendMessage',
      context: {'messageLength': message.length},
    );

    final requestDto = SendTandyMessageRequestDto(
      message: message,
      language: language,
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.tandySend,
      data: requestDto.toJson(),
      receiveTimeout: const Duration(seconds: 45),
    );
  }

  // -----------------------------------------------------------------------
  // Conversation management
  // -----------------------------------------------------------------------

  /// Clears the current Tandy conversation.
  Future<void> clearConversation() async {
    AppLogger.debug(
      'Clearing Tandy conversation',
      operation: '$_tag.clearConversation',
    );

    await _dioClient.delete<Object?>(ApiEndpoints.tandyConversation);
  }

  /// Sets the preferred language for Tandy responses.
  Future<void> setLanguage({required String language}) async {
    AppLogger.debug(
      'Setting Tandy language',
      operation: '$_tag.setLanguage',
      context: {'language': language},
    );

    final requestDto = SetTandyLanguageRequestDto(language: language);

    await _dioClient.post<Object?>(
      ApiEndpoints.tandyLanguage,
      data: requestDto.toJson(),
    );
  }

  /// Updates the card-expanded state for a specific message.
  Future<void> expandCard({
    required String messageId,
    required bool isExpanded,
  }) async {
    AppLogger.debug(
      'Expanding Tandy card',
      operation: '$_tag.expandCard',
      context: {'messageId': messageId, 'isExpanded': isExpanded},
    );

    await _dioClient.patch<Object?>(
      ApiEndpoints.tandyCardExpanded(messageId),
      data: {'expanded': isExpanded},
    );
  }

  /// Rates a Tandy reply: 1 = thumbs up, -1 = thumbs down, 0 = clear.
  Future<void> rateMessage({
    required String messageId,
    required int rating,
  }) async {
    AppLogger.debug(
      'Rating Tandy message',
      operation: '$_tag.rateMessage',
      context: {'messageId': messageId, 'rating': rating},
    );

    await _dioClient.post<Object?>(
      ApiEndpoints.tandyMessageRating(messageId),
      data: {'rating': rating},
    );
  }

  /// Records a tap on a sponsor card CTA. Fire-and-forget — failures swallowed
  /// so a flaky network never blocks the outbound link the user just tapped.
  Future<void> recordSponsorClick({required String impressionId}) async {
    AppLogger.debug(
      'Recording sponsor click',
      operation: '$_tag.recordSponsorClick',
      context: {'impressionId': impressionId},
    );

    await _dioClient.post<Object?>(
      ApiEndpoints.tandySponsorImpressionClick(impressionId),
    );
  }
}
