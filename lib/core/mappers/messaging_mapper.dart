import 'package:tander_flutter_v3/core/contracts/messaging_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';

/// Pure functions converting messaging DTOs to domain models.
///
/// All conversions are null-safe with documented fallback behaviour.
/// The mapper never performs I/O or mutates external state.
abstract final class MessagingMapper {
  /// Maps a [ConversationDto] to a [ConversationItem] domain model.
  static ConversationItem mapConversationDto(
    ConversationDto dto, {
    required String currentUserId,
  }) {
    final otherUser = dto.otherUser;
    final primaryPhoto = otherUser?.photos?.firstWhere(
      (p) => p.primary,
      orElse: () => otherUser?.photos?.firstOrNull ?? const ConversationPhotoDto(url: ''),
    );

    final updatedAt = DateTime.tryParse(dto.lastMessageAt ?? '') ?? DateTime.now();

    return ConversationItem(
      conversationId: dto.id,
      roomId: dto.connectionId ?? dto.id,
      participant: ParticipantSummary(
        userId: dto.otherUserId,
        username: otherUser?.firstName ?? 'User',
        profilePhotoUrl: primaryPhoto?.url,
        isOnline: false,
      ),
      lastMessage: _mapLastMessage(dto),
      unreadCount: dto.unreadCount,
      isMuted: dto.muted,
      updatedAt: updatedAt,
    );
  }

  /// Maps a [MessageDto] to a [MessageItem] domain model.
  static MessageItem mapMessageDto(MessageDto dto) {
    final mediaType = _parseMediaType(dto.kind);

    return MessageItem(
      messageId: dto.id,
      conversationId: dto.conversationId,
      roomId: dto.conversationId,
      senderUserId: dto.senderUserId,
      senderUsername: null,
      body: dto.body,
      media: dto.mediaUrl != null && mediaType != null
          ? MessageMedia(
              url: dto.mediaUrl!,
              type: mediaType,
              durationSeconds: null,
            )
          : null,
      sentAt: DateTime.tryParse(dto.sentAt) ?? DateTime.now(),
      readAt: dto.readAt != null ? DateTime.tryParse(dto.readAt!) : null,
      deliveryState: dto.readAt != null
          ? MessageDeliveryState.read
          : (dto.deliveredAt != null ? MessageDeliveryState.delivered : MessageDeliveryState.sent),
      isDeleted: false,
      isUnsent: false,
      unsentAt: null,
      unsentByUserId: null,
    );
  }

  /// Parses a STOMP message payload into a [MessageItem].
  ///
  /// Returns `null` if the payload is missing critical fields.
  static MessageItem? mapStompPayload(
    Map<String, Object?> payload, {
    required String conversationId,
    required String roomId,
  }) {
    final rawMessageId = payload['messageId'];
    if (rawMessageId == null) return null;

    final senderId = _safeString(payload['senderId']);
    final body = payload['text'] is String
        ? payload['text'] as String
        : (payload['content'] is String ? payload['content'] as String : null);

    final rawMediaUrl = payload['mediaUrl'];
    final hasMedia = rawMediaUrl is String && rawMediaUrl.isNotEmpty;
    final rawType = _safeString(payload['messageType']).toUpperCase();
    final mediaType = rawType == 'VOICE'
        ? MessageMediaType.voice
        : (hasMedia ? MessageMediaType.image : null);

    final rawTimestamp = payload['timestamp'];
    final sentAt = rawTimestamp is int
        ? DateTime.fromMillisecondsSinceEpoch(rawTimestamp)
        : DateTime.now();

    return MessageItem(
      messageId: rawMessageId.toString(),
      conversationId: conversationId,
      roomId: roomId,
      senderUserId: senderId,
      senderUsername: _safeString(payload['senderUsername']),
      body: body,
      media: hasMedia && mediaType != null
          ? MessageMedia(
              url: rawMediaUrl,
              type: mediaType,
              durationSeconds: payload['mediaDurationSeconds'] is int
                  ? payload['mediaDurationSeconds'] as int
                  : null,
            )
          : null,
      sentAt: sentAt,
      deliveryState: MessageDeliveryState.sent,
      isDeleted: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static LastMessagePreview? _mapLastMessage(ConversationDto dto) {
    if (dto.lastMessageBody == null || dto.lastMessageAt == null) return null;

    return LastMessagePreview(
      messageId: '0',
      body: dto.lastMessageBody,
      sentAt: DateTime.tryParse(dto.lastMessageAt!) ?? DateTime.now(),
      senderId: '',
    );
  }

  static MessageMediaType? _parseMediaType(String? kind) {
    if (kind == 'IMAGE') return MessageMediaType.image;
    if (kind == 'VOICE') return MessageMediaType.voice;
    return null;
  }

  static String _safeString(Object? value) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return '';
  }
}
