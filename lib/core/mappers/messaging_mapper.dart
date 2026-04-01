import 'dart:math' as math;

import 'package:tander_flutter_v3/core/contracts/messaging_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';

/// Pure functions converting messaging DTOs to domain models.
///
/// All conversions are null-safe with documented fallback behaviour.
/// The mapper never performs I/O or mutates external state.
abstract final class MessagingMapper {
  /// Computes the deterministic room ID for a DM between two users.
  ///
  /// Format: `dm_{min(id1,id2)}_{max(id1,id2)}`.
  static String computeRoomId(int id1, int id2) {
    return 'dm_${math.min(id1, id2)}_${math.max(id1, id2)}';
  }

  /// Maps a [ConversationDto] to a [ConversationItem] domain model.
  ///
  /// [currentUserId] identifies the logged-in user so we can resolve
  /// which side of the conversation is the "other" participant.
  static ConversationItem mapConversationDto(
    ConversationDto dto, {
    required String currentUserId,
  }) {
    final currentUserNumericId = int.parse(currentUserId);
    final isCurrentUserOne = dto.user1Id == currentUserNumericId;

    final otherUserId = isCurrentUserOne ? dto.user2Id : dto.user1Id;
    final otherDisplayName = isCurrentUserOne
        ? (dto.user2DisplayName ?? dto.user2Username)
        : (dto.user1DisplayName ?? dto.user1Username);
    final otherPhotoUrl = isCurrentUserOne
        ? dto.user2ProfilePhotoUrl
        : dto.user1ProfilePhotoUrl;

    final roomId = computeRoomId(dto.user1Id, dto.user2Id);
    final updatedAt = DateTime.tryParse(dto.lastMessageAt ?? dto.createdAt) ??
        DateTime.now();

    return ConversationItem(
      conversationId: dto.id.toString(),
      roomId: roomId,
      participant: ParticipantSummary(
        userId: otherUserId.toString(),
        username: otherDisplayName,
        profilePhotoUrl: otherPhotoUrl,
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
    final roomId = computeRoomId(dto.senderId, dto.receiverId);
    final mediaType = _parseMediaType(dto.messageType);

    return MessageItem(
      messageId: dto.id.toString(),
      conversationId: dto.conversationId.toString(),
      roomId: roomId,
      senderUserId: dto.senderId.toString(),
      senderUsername: dto.senderUsername,
      body: dto.content,
      media: dto.mediaUrl != null && mediaType != null
          ? MessageMedia(
              url: dto.mediaUrl!,
              type: mediaType,
              durationSeconds: dto.mediaDurationSeconds,
            )
          : null,
      sentAt: DateTime.tryParse(dto.sentAt) ?? DateTime.now(),
      readAt: dto.status == 'READ'
          ? (DateTime.tryParse(dto.sentAt) ?? DateTime.now())
          : null,
      deliveryState: _parseDeliveryState(dto.status),
      isDeleted: dto.unsent,
      isUnsent: dto.unsent,
      unsentAt: dto.unsentAt != null ? DateTime.tryParse(dto.unsentAt!) : null,
      unsentByUserId: dto.unsentByUserId?.toString(),
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
    if (dto.lastMessage == null || dto.lastMessageAt == null) return null;

    return LastMessagePreview(
      messageId: '0',
      body: dto.lastMessage,
      sentAt: DateTime.tryParse(dto.lastMessageAt!) ?? DateTime.now(),
      senderId: '',
    );
  }

  static MessageDeliveryState _parseDeliveryState(String status) {
    return switch (status) {
      'READ' => MessageDeliveryState.read,
      'DELIVERED' => MessageDeliveryState.delivered,
      _ => MessageDeliveryState.sent,
    };
  }

  static MessageMediaType? _parseMediaType(String? messageType) {
    final lower = messageType?.toLowerCase();
    if (lower == 'image') return MessageMediaType.image;
    if (lower == 'voice') return MessageMediaType.voice;
    return null;
  }

  static String _safeString(Object? value) {
    if (value is String) return value;
    if (value != null) return value.toString();
    return '';
  }
}
