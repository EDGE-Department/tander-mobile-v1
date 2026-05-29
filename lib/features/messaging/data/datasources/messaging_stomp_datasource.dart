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

  /// Subscribe to new messages arriving in a conversation.
  ///
  /// [roomId] is threaded into the mapped [MessageItem] for downstream consumers.
  StompUnsubscribeCallback subscribeToConversation(
    String conversationId, {
    required String roomId,
    required void Function(MessageItem message) onMessage,
  }) {
    final destination = '/topic/conversation.$conversationId';
    AppLogger.debug(
      'Subscribing to conversation messages',
      operation: '$_tag.subscribeToConversation',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(destination, (
      Map<String, Object?> body,
    ) {
      final message = MessagingMapper.mapStompPayload(
        body,
        conversationId: conversationId,
        roomId: roomId,
      );
      if (message != null) {
        onMessage(message);
      }
    });
  }

  /// Subscribe to typing indicators in [conversationId].
  StompUnsubscribeCallback subscribeToTyping(
    String conversationId, {
    required void Function({required bool isTyping, required String usrId})
    onTyping,
  }) {
    final destination = '/topic/conversation.$conversationId/typing';
    AppLogger.debug(
      'Subscribing to typing indicators',
      operation: '$_tag.subscribeToTyping',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(destination, (
      Map<String, Object?> body,
    ) {
      final rawUserId = body['userId'];
      final usrId = rawUserId?.toString() ?? '';

      final isTyping = body['isTyping'] == true;
      onTyping(isTyping: isTyping, usrId: usrId);
    });
  }

  /// Subscribe to delivery receipts in a conversation.
  StompUnsubscribeCallback subscribeToDelivered(
    String conversationId, {
    required void Function(String messageId) onDelivered,
  }) {
    final destination = '/topic/conversation.$conversationId/delivered';
    AppLogger.debug(
      'Subscribing to delivery receipts',
      operation: '$_tag.subscribeToDelivered',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(destination, (
      Map<String, Object?> body,
    ) {
      final rawMessageId = body['messageId'];
      final messageId = rawMessageId?.toString();
      if (messageId != null && messageId.isNotEmpty) {
        onDelivered(messageId);
      }
    });
  }

  /// Subscribe to read receipts in a conversation.
  StompUnsubscribeCallback subscribeToRead(
    String conversationId, {
    required void Function({required String readByUserId}) onRead,
  }) {
    final destination = '/topic/conversation.$conversationId/read';
    AppLogger.debug(
      'Subscribing to read receipts',
      operation: '$_tag.subscribeToRead',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(destination, (
      Map<String, Object?> body,
    ) {
      final readBy = body['readBy'] ?? body['userId'];
      if (readBy != null) {
        onRead(readByUserId: readBy.toString());
      }
    });
  }

  // -----------------------------------------------------------------------
  // Sends
  // -----------------------------------------------------------------------

  /// Sends a typing indicator for [conversationId].
  void sendTypingIndicator(String conversationId, {required bool isTyping}) {
    StompClientManager.instance.send(
      '/app/chat.typing.$conversationId',
      <String, Object?>{'isTyping': isTyping},
    );
  }

  /// Sends a delivery receipt for a specific [messageId].
  void sendDeliveryReceipt({
    required String messageId,
    required String conversationId,
  }) {
    StompClientManager.instance.send('/app/chat.delivered', <String, Object?>{
      'messageId': messageId,
      'conversationId': conversationId,
    });
  }

  /// Sends a read receipt for a [conversationId].
  void sendReadReceipt({required String conversationId}) {
    StompClientManager.instance.send('/app/chat.read', <String, Object?>{
      'conversationId': conversationId,
    });
  }
}
