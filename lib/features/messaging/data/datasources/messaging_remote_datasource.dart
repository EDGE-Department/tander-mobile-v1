import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// All messaging-related HTTP calls, delegating to [DioClient].
///
/// Methods return raw [Response] objects so the repository layer
/// can map DTOs to domain models and wrap errors in [Result].
final class MessagingRemoteDatasource {
  const MessagingRemoteDatasource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static const String _tag = 'MessagingRemoteDatasource';

  // -----------------------------------------------------------------------
  // Conversations
  // -----------------------------------------------------------------------

  /// Fetches the authenticated user's conversation list.
  Future<Response<List<Object?>>> fetchConversations() {
    AppLogger.debug(
      'Fetching conversations',
      operation: '$_tag.fetchConversations',
    );

    return _dioClient.get<List<Object?>>(ApiEndpoints.conversations);
  }

  // -----------------------------------------------------------------------
  // Messages
  // -----------------------------------------------------------------------

  /// Fetches the message thread for a given [conversationId].
  Future<Response<List<Object?>>> fetchMessages({
    required int conversationId,
  }) {
    AppLogger.debug(
      'Fetching messages',
      operation: '$_tag.fetchMessages',
      context: {'conversationId': conversationId},
    );

    return _dioClient.get<List<Object?>>(
      ApiEndpoints.conversationMessages(conversationId),
    );
  }

  /// Sends a plain text message.
  Future<Response<Map<String, Object?>>> sendTextMessage({
    required int receiverId,
    required String content,
  }) {
    AppLogger.debug(
      'Sending text message',
      operation: '$_tag.sendTextMessage',
      context: {'receiverId': receiverId},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.sendMessage,
      data: {'receiverId': receiverId, 'content': content},
    );
  }

  /// Sends an image message via multipart upload.
  Future<Response<Map<String, Object?>>> sendImageMessage({
    required String roomId,
    required String filePath,
    required String fileName,
  }) {
    AppLogger.debug(
      'Sending image message',
      operation: '$_tag.sendImageMessage',
      context: {'roomId': roomId},
    );

    final formData = FormData.fromMap(<String, Object>{
      'roomId': roomId,
      'image': MultipartFile.fromFileSync(filePath, filename: fileName),
    });

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.sendImageMessage,
      data: formData,
    );
  }

  /// Sends a voice message via multipart upload.
  Future<Response<Map<String, Object?>>> sendVoiceMessage({
    required String roomId,
    required String filePath,
    required String fileName,
    required int durationSeconds,
  }) {
    AppLogger.debug(
      'Sending voice message',
      operation: '$_tag.sendVoiceMessage',
      context: {'roomId': roomId, 'durationSeconds': durationSeconds},
    );

    final formData = FormData.fromMap(<String, Object>{
      'roomId': roomId,
      'duration': durationSeconds,
      'audio': MultipartFile.fromFileSync(filePath, filename: fileName),
    });

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.sendVoiceMessage,
      data: formData,
    );
  }

  // -----------------------------------------------------------------------
  // Read receipts & muting
  // -----------------------------------------------------------------------

  /// Marks all messages in a conversation as read (server-side).
  Future<void> markConversationRead({required int conversationId}) async {
    AppLogger.debug(
      'Marking conversation read',
      operation: '$_tag.markConversationRead',
      context: {'conversationId': conversationId},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.markRead(conversationId),
    );
  }

  /// Starts a new conversation with [userId] if none exists.
  Future<Response<Map<String, Object?>>> startConversation({
    required int userId,
  }) {
    AppLogger.debug(
      'Starting conversation',
      operation: '$_tag.startConversation',
      context: {'userId': userId},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.startConversation(userId),
    );
  }
}
