import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/mappers/messaging_mapper.dart';
import 'package:tander_flutter_v3/core/realtime/stomp_client_manager.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Real-time messaging operations over STOMP WebSocket.
///
/// Uses [StompClientManager.instance] for all subscribe/send operations.
/// Every subscription returns an [StompUnsubscribeCallback] that the caller
/// MUST invoke on dispose to avoid resource leaks.
final class MessagingStompDatasource {
  const MessagingStompDatasource();

  static const String _tag = 'MessagingStompDatasource';

  // -----------------------------------------------------------------------
  // Subscriptions
  // -----------------------------------------------------------------------

  /// Subscribe to new messages arriving in [roomId].
  ///
  /// [conversationId] is threaded into the mapped [MessageItem] for
  /// downstream consumers.
  StompUnsubscribeCallback subscribeToRoom(
    String roomId, {
    required String conversationId,
    required void Function(MessageItem message) onMessage,
  }) {
    final destination = '/topic/chat/$roomId';
    AppLogger.debug(
      'Subscribing to room messages',
      operation: '$_tag.subscribeToRoom',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(
      destination,
      (Map<String, Object?> body) {
        final message = MessagingMapper.mapStompPayload(
          body,
          conversationId: conversationId,
          roomId: roomId,
        );
        if (message != null) {
          onMessage(message);
        }
      },
    );
  }

  /// Subscribe to typing indicators in [roomId].
  StompUnsubscribeCallback subscribeToTyping(
    String roomId, {
    required void Function({required bool isTyping, required int userId})
        onTyping,
  }) {
    final destination = '/topic/chat/$roomId/typing';
    AppLogger.debug(
      'Subscribing to typing indicators',
      operation: '$_tag.subscribeToTyping',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(
      destination,
      (Map<String, Object?> body) {
        final rawUserId = body['userId'];
        final userId = switch (rawUserId) {
          final int intId => intId,
          final String stringId => int.tryParse(stringId) ?? 0,
          _ => 0,
        };

        final isTyping = body['isTyping'] == true;
        onTyping(isTyping: isTyping, userId: userId);
      },
    );
  }

  /// Subscribe to delivery receipts in [roomId].
  StompUnsubscribeCallback subscribeToDelivered(
    String roomId, {
    required void Function(int messageId) onDelivered,
  }) {
    final destination = '/topic/chat/$roomId/delivered';
    AppLogger.debug(
      'Subscribing to delivery receipts',
      operation: '$_tag.subscribeToDelivered',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(
      destination,
      (Map<String, Object?> body) {
        final rawMessageId = body['messageId'];
        final messageId = switch (rawMessageId) {
          final int intId => intId,
          final String stringId => int.tryParse(stringId),
          _ => null,
        };
        if (messageId != null) {
          onDelivered(messageId);
        }
      },
    );
  }

  /// Subscribe to read receipts in [roomId].
  StompUnsubscribeCallback subscribeToRead(
    String roomId, {
    required void Function({required String readByUserId}) onRead,
  }) {
    final destination = '/topic/chat/$roomId/read';
    AppLogger.debug(
      'Subscribing to read receipts',
      operation: '$_tag.subscribeToRead',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(
      destination,
      (Map<String, Object?> body) {
        final readBy = body['readBy'];
        if (readBy != null) {
          onRead(readByUserId: readBy.toString());
        }
      },
    );
  }

  // -----------------------------------------------------------------------
  // Sends
  // -----------------------------------------------------------------------

  /// Sends a typing indicator for [roomId].
  void sendTypingIndicator(String roomId, {required bool isTyping}) {
    StompClientManager.instance.send(
      '/app/chat.typing/$roomId',
      <String, Object?>{
        'conversationId': 0,
        'receiverId': 0,
        'isTyping': isTyping,
      },
    );
  }

  /// Sends a delivery receipt for a specific [messageId].
  void sendDeliveryReceipt({
    required int messageId,
    required String roomId,
  }) {
    StompClientManager.instance.send(
      '/app/chat.delivered',
      <String, Object?>{
        'messageId': messageId,
        'roomId': roomId,
      },
    );
  }

  /// Sends a read receipt for a [conversationId].
  void sendReadReceipt({required int conversationId}) {
    StompClientManager.instance.send(
      '/app/chat.read',
      <String, Object?>{'conversationId': conversationId},
    );
  }
}
