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
    required this.otherUserId,
    this.connectionId,
    this.otherUser,
    this.lastMessageAt,
    this.lastMessageBody,
    this.unreadCount = 0,
    this.muted = false,
  });

  factory ConversationDto.fromJson(Map<String, Object?> json) =>
      _$ConversationDtoFromJson(json);

  final String id;
  final String? connectionId;
  final String otherUserId;
  final ConversationOtherUserDto? otherUser;
  final String? lastMessageAt;
  final String? lastMessageBody;
  final int unreadCount;
  final bool muted;

  Map<String, Object?> toJson() => _$ConversationDtoToJson(this);
}

@JsonSerializable()
class ConversationOtherUserDto {
  const ConversationOtherUserDto({
    required this.id,
    this.firstName,
    this.age,
    this.bio,
    this.photos,
  });

  factory ConversationOtherUserDto.fromJson(Map<String, Object?> json) =>
      _$ConversationOtherUserDtoFromJson(json);

  final String id;
  final String? firstName;
  final int? age;
  final String? bio;
  final List<ConversationPhotoDto>? photos;

  Map<String, Object?> toJson() => _$ConversationOtherUserDtoToJson(this);
}

@JsonSerializable()
class ConversationPhotoDto {
  const ConversationPhotoDto({
    required this.url,
    this.primary = false,
    this.sortOrder,
  });

  factory ConversationPhotoDto.fromJson(Map<String, Object?> json) =>
      _$ConversationPhotoDtoFromJson(json);

  final String url;
  final bool primary;
  final int? sortOrder;

  Map<String, Object?> toJson() => _$ConversationPhotoDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Message
// ---------------------------------------------------------------------------

@JsonSerializable()
class MessageDto {
  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.kind,
    required this.sentAt,
    this.body,
    this.mediaUrl,
    this.mediaContentType,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageDto.fromJson(Map<String, Object?> json) =>
      _$MessageDtoFromJson(json);

  final String id;
  final String conversationId;
  final String senderUserId;
  final String kind; // TEXT, IMAGE, VOICE, SYSTEM
  final String? body;
  final String? mediaUrl;
  final String? mediaContentType;
  final String sentAt;
  final String? deliveredAt;
  final String? readAt;

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
