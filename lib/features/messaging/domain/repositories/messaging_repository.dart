import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

/// Contract for all messaging operations.
///
/// Implementations live in the data layer and may use Dio, STOMP, or
/// any other infrastructure concern. The domain and presentation layers
/// only know this interface.
abstract interface class MessagingRepository {
  /// Fetches all conversations for the authenticated user.
  Future<Result<List<ConversationItem>>> fetchConversations({
    required String currentUserId,
  });

  /// Fetches the message thread for a given [conversationId].
  Future<Result<List<MessageItem>>> fetchMessages({
    required int conversationId,
  });

  /// Sends a plain text message to [receiverId].
  Future<Result<MessageItem>> sendTextMessage({
    required int receiverId,
    required String content,
  });

  /// Sends an image message from a local [filePath].
  Future<Result<MessageItem>> sendImageMessage({
    required String roomId,
    required String filePath,
    required String fileName,
  });

  /// Sends a voice message from a local [filePath].
  Future<Result<MessageItem>> sendVoiceMessage({
    required String roomId,
    required String filePath,
    required String fileName,
    required int durationSeconds,
  });

  /// Marks all messages in [conversationId] as read (server-side).
  Future<Result<void>> markConversationRead({
    required int conversationId,
  });
}
