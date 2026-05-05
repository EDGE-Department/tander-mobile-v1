// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationDto _$ConversationDtoFromJson(Map<String, dynamic> json) =>
    ConversationDto(
      id: json['id'] as String,
      otherUserId: json['otherUserId'] as String,
      connectionId: json['connectionId'] as String?,
      otherUser: json['otherUser'] == null
          ? null
          : ConversationOtherUserDto.fromJson(
              json['otherUser'] as Map<String, dynamic>,
            ),
      lastMessageAt: json['lastMessageAt'] as String?,
      lastMessageBody: json['lastMessageBody'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      muted: json['muted'] as bool? ?? false,
    );

Map<String, dynamic> _$ConversationDtoToJson(ConversationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'connectionId': instance.connectionId,
      'otherUserId': instance.otherUserId,
      'otherUser': instance.otherUser,
      'lastMessageAt': instance.lastMessageAt,
      'lastMessageBody': instance.lastMessageBody,
      'unreadCount': instance.unreadCount,
      'muted': instance.muted,
    };

ConversationOtherUserDto _$ConversationOtherUserDtoFromJson(
  Map<String, dynamic> json,
) => ConversationOtherUserDto(
  id: json['id'] as String,
  firstName: json['firstName'] as String?,
  age: (json['age'] as num?)?.toInt(),
  bio: json['bio'] as String?,
  photos: (json['photos'] as List<dynamic>?)
      ?.map((e) => ConversationPhotoDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ConversationOtherUserDtoToJson(
  ConversationOtherUserDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'age': instance.age,
  'bio': instance.bio,
  'photos': instance.photos,
};

ConversationPhotoDto _$ConversationPhotoDtoFromJson(
  Map<String, dynamic> json,
) => ConversationPhotoDto(
  url: json['url'] as String,
  primary: json['primary'] as bool? ?? false,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$ConversationPhotoDtoToJson(
  ConversationPhotoDto instance,
) => <String, dynamic>{
  'url': instance.url,
  'primary': instance.primary,
  'sortOrder': instance.sortOrder,
};

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  senderUserId: json['senderUserId'] as String,
  kind: json['kind'] as String,
  sentAt: json['sentAt'] as String,
  body: json['body'] as String?,
  mediaUrl: json['mediaUrl'] as String?,
  mediaContentType: json['mediaContentType'] as String?,
  deliveredAt: json['deliveredAt'] as String?,
  readAt: json['readAt'] as String?,
);

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderUserId': instance.senderUserId,
      'kind': instance.kind,
      'body': instance.body,
      'mediaUrl': instance.mediaUrl,
      'mediaContentType': instance.mediaContentType,
      'sentAt': instance.sentAt,
      'deliveredAt': instance.deliveredAt,
      'readAt': instance.readAt,
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
