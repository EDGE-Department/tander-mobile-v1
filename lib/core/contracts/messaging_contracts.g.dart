// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationDto _$ConversationDtoFromJson(Map<String, dynamic> json) =>
    ConversationDto(
      id: (json['id'] as num).toInt(),
      user1Id: (json['user1Id'] as num).toInt(),
      user1Username: json['user1Username'] as String,
      user2Id: (json['user2Id'] as num).toInt(),
      user2Username: json['user2Username'] as String,
      createdAt: json['createdAt'] as String,
      unreadCount: (json['unreadCount'] as num).toInt(),
      active: json['active'] as bool,
      muted: json['muted'] as bool,
      user1DisplayName: json['user1DisplayName'] as String?,
      user1ProfilePhotoUrl: json['user1ProfilePhotoUrl'] as String?,
      user2DisplayName: json['user2DisplayName'] as String?,
      user2ProfilePhotoUrl: json['user2ProfilePhotoUrl'] as String?,
      lastMessageAt: json['lastMessageAt'] as String?,
      lastMessage: json['lastMessage'] as String?,
    );

Map<String, dynamic> _$ConversationDtoToJson(ConversationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user1Id': instance.user1Id,
      'user1Username': instance.user1Username,
      'user1DisplayName': instance.user1DisplayName,
      'user1ProfilePhotoUrl': instance.user1ProfilePhotoUrl,
      'user2Id': instance.user2Id,
      'user2Username': instance.user2Username,
      'user2DisplayName': instance.user2DisplayName,
      'user2ProfilePhotoUrl': instance.user2ProfilePhotoUrl,
      'createdAt': instance.createdAt,
      'lastMessageAt': instance.lastMessageAt,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
      'active': instance.active,
      'muted': instance.muted,
    };

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
  id: (json['id'] as num).toInt(),
  conversationId: (json['conversationId'] as num).toInt(),
  senderId: (json['senderId'] as num).toInt(),
  senderUsername: json['senderUsername'] as String,
  receiverId: (json['receiverId'] as num).toInt(),
  receiverUsername: json['receiverUsername'] as String,
  sentAt: json['sentAt'] as String,
  status: json['status'] as String,
  content: json['content'] as String?,
  messageType: json['messageType'] as String?,
  mediaUrl: json['mediaUrl'] as String?,
  mediaDurationSeconds: (json['mediaDurationSeconds'] as num?)?.toInt(),
  unsent: json['unsent'] as bool? ?? false,
  unsentAt: json['unsentAt'] as String?,
  unsentByUserId: (json['unsentByUserId'] as num?)?.toInt(),
);

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderId': instance.senderId,
      'senderUsername': instance.senderUsername,
      'receiverId': instance.receiverId,
      'receiverUsername': instance.receiverUsername,
      'content': instance.content,
      'sentAt': instance.sentAt,
      'status': instance.status,
      'messageType': instance.messageType,
      'mediaUrl': instance.mediaUrl,
      'mediaDurationSeconds': instance.mediaDurationSeconds,
      'unsent': instance.unsent,
      'unsentAt': instance.unsentAt,
      'unsentByUserId': instance.unsentByUserId,
    };

SendMessageRequestDto _$SendMessageRequestDtoFromJson(
  Map<String, dynamic> json,
) => SendMessageRequestDto(
  receiverId: (json['receiverId'] as num).toInt(),
  content: json['content'] as String,
);

Map<String, dynamic> _$SendMessageRequestDtoToJson(
  SendMessageRequestDto instance,
) => <String, dynamic>{
  'receiverId': instance.receiverId,
  'content': instance.content,
};

StompMessagePayload _$StompMessagePayloadFromJson(Map<String, dynamic> json) =>
    StompMessagePayload(
      type: json['type'] as String,
      message: MessageDto.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StompMessagePayloadToJson(
  StompMessagePayload instance,
) => <String, dynamic>{'type': instance.type, 'message': instance.message};

StompTypingPayload _$StompTypingPayloadFromJson(Map<String, dynamic> json) =>
    StompTypingPayload(
      type: json['type'] as String,
      userId: json['userId'] as String,
      isTyping: json['isTyping'] as bool,
      roomId: json['roomId'] as String,
    );

Map<String, dynamic> _$StompTypingPayloadToJson(StompTypingPayload instance) =>
    <String, dynamic>{
      'type': instance.type,
      'userId': instance.userId,
      'isTyping': instance.isTyping,
      'roomId': instance.roomId,
    };

StompReadPayload _$StompReadPayloadFromJson(Map<String, dynamic> json) =>
    StompReadPayload(
      type: json['type'] as String,
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String,
      lastReadMessageId: json['lastReadMessageId'] as String,
    );

Map<String, dynamic> _$StompReadPayloadToJson(StompReadPayload instance) =>
    <String, dynamic>{
      'type': instance.type,
      'conversationId': instance.conversationId,
      'userId': instance.userId,
      'lastReadMessageId': instance.lastReadMessageId,
    };

StompDeliveredPayload _$StompDeliveredPayloadFromJson(
  Map<String, dynamic> json,
) => StompDeliveredPayload(
  type: json['type'] as String,
  conversationId: json['conversationId'] as String,
  messageId: json['messageId'] as String,
  userId: json['userId'] as String,
);

Map<String, dynamic> _$StompDeliveredPayloadToJson(
  StompDeliveredPayload instance,
) => <String, dynamic>{
  'type': instance.type,
  'conversationId': instance.conversationId,
  'messageId': instance.messageId,
  'userId': instance.userId,
};
