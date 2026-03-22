/// Messaging domain -- raw backend DTOs.
/// These match the Java ConversationDTO and ChatMessageDTO classes exactly.
library;

import 'package:json_annotation/json_annotation.dart';

part 'messaging_contracts.g.dart';

// ---------------------------------------------------------------------------
// Conversation
// ---------------------------------------------------------------------------

@JsonSerializable()
class ConversationDto {
  const ConversationDto({
    required this.id,
    required this.user1Id,
    required this.user1Username,
    required this.user2Id,
    required this.user2Username,
    required this.createdAt,
    required this.unreadCount,
    required this.active,
    required this.muted,
    this.user1DisplayName,
    this.user1ProfilePhotoUrl,
    this.user2DisplayName,
    this.user2ProfilePhotoUrl,
    this.lastMessageAt,
    this.lastMessage,
  });

  factory ConversationDto.fromJson(Map<String, Object?> json) =>
      _$ConversationDtoFromJson(json);

  final int id;
  final int user1Id;
  final String user1Username;
  final String? user1DisplayName;
  final String? user1ProfilePhotoUrl;
  final int user2Id;
  final String user2Username;
  final String? user2DisplayName;
  final String? user2ProfilePhotoUrl;
  final String createdAt;
  final String? lastMessageAt;
  final String? lastMessage;
  final int unreadCount;

  /// Serialized from Java boolean isActive -> JSON key "active".
  final bool active;

  /// Serialized from Java boolean isMuted -> JSON key "muted".
  final bool muted;

  Map<String, Object?> toJson() => _$ConversationDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Message
// ---------------------------------------------------------------------------

@JsonSerializable()
class MessageDto {
  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.receiverId,
    required this.receiverUsername,
    required this.sentAt,
    required this.status,
    this.content,
    this.messageType,
    this.mediaUrl,
    this.mediaDurationSeconds,
  });

  factory MessageDto.fromJson(Map<String, Object?> json) =>
      _$MessageDtoFromJson(json);

  final int id;
  final int conversationId;
  final int senderId;
  final String senderUsername;
  final int receiverId;
  final String receiverUsername;
  final String? content;
  final String sentAt;

  /// 'SENT', 'DELIVERED', or 'READ'
  final String status;
  final String? messageType;
  final String? mediaUrl;
  final int? mediaDurationSeconds;

  Map<String, Object?> toJson() => _$MessageDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Send message request
// ---------------------------------------------------------------------------

@JsonSerializable()
class SendMessageRequestDto {
  const SendMessageRequestDto({
    required this.receiverId,
    required this.content,
  });

  factory SendMessageRequestDto.fromJson(Map<String, Object?> json) =>
      _$SendMessageRequestDtoFromJson(json);

  final int receiverId;
  final String content;

  Map<String, Object?> toJson() => _$SendMessageRequestDtoToJson(this);
}

// ---------------------------------------------------------------------------
// STOMP realtime payloads
// ---------------------------------------------------------------------------

@JsonSerializable()
class StompMessagePayload {
  const StompMessagePayload({
    required this.type,
    required this.message,
  });

  factory StompMessagePayload.fromJson(Map<String, Object?> json) =>
      _$StompMessagePayloadFromJson(json);

  /// 'message.created', 'message.updated', or 'message.deleted'
  final String type;
  final MessageDto message;

  Map<String, Object?> toJson() => _$StompMessagePayloadToJson(this);
}

@JsonSerializable()
class StompTypingPayload {
  const StompTypingPayload({
    required this.type,
    required this.userId,
    required this.isTyping,
    required this.roomId,
  });

  factory StompTypingPayload.fromJson(Map<String, Object?> json) =>
      _$StompTypingPayloadFromJson(json);

  /// Always 'message.typing'
  final String type;
  final String userId;
  final bool isTyping;
  final String roomId;

  Map<String, Object?> toJson() => _$StompTypingPayloadToJson(this);
}

@JsonSerializable()
class StompReadPayload {
  const StompReadPayload({
    required this.type,
    required this.conversationId,
    required this.userId,
    required this.lastReadMessageId,
  });

  factory StompReadPayload.fromJson(Map<String, Object?> json) =>
      _$StompReadPayloadFromJson(json);

  /// Always 'message.read'
  final String type;
  final String conversationId;
  final String userId;
  final String lastReadMessageId;

  Map<String, Object?> toJson() => _$StompReadPayloadToJson(this);
}

@JsonSerializable()
class StompDeliveredPayload {
  const StompDeliveredPayload({
    required this.type,
    required this.conversationId,
    required this.messageId,
    required this.userId,
  });

  factory StompDeliveredPayload.fromJson(Map<String, Object?> json) =>
      _$StompDeliveredPayloadFromJson(json);

  /// Always 'message.delivered'
  final String type;
  final String conversationId;
  final String messageId;
  final String userId;

  Map<String, Object?> toJson() => _$StompDeliveredPayloadToJson(this);
}
