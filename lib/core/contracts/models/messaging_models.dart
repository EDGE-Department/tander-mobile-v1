/// Messaging domain models — consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
library;

import 'package:flutter/foundation.dart';

// ── Message Types ────────────────────────────────────────────

/// Delivery lifecycle of a single message.
enum MessageDeliveryState {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Kind of media attached to a message.
enum MessageMediaType {
  image,
  voice,
}

// ── Supporting Models ────────────────────────────────────────

@immutable
class ParticipantSummary {
  const ParticipantSummary({
    required this.userId,
    required this.username,
    required this.isOnline,
    this.profilePhotoUrl,
    this.lastSeenAt,
  });

  final String userId;
  final String username;
  final String? profilePhotoUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantSummary &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'ParticipantSummary(userId: $userId, username: $username)';
}

@immutable
class LastMessagePreview {
  const LastMessagePreview({
    required this.messageId,
    required this.sentAt,
    required this.senderId,
    this.body,
    this.mediaType,
  });

  final String messageId;
  final String? body;
  final MessageMediaType? mediaType;
  final DateTime sentAt;
  final String senderId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastMessagePreview &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() => 'LastMessagePreview(id: $messageId)';
}

@immutable
class MessageMedia {
  const MessageMedia({
    required this.url,
    required this.type,
    this.durationSeconds,
  });

  final String url;
  final MessageMediaType type;
  final int? durationSeconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageMedia &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          type == other.type;

  @override
  int get hashCode => Object.hash(url, type);

  @override
  String toString() => 'MessageMedia(type: ${type.name}, url: $url)';
}

// ── Conversation Item ────────────────────────────────────────

@immutable
class ConversationItem {
  const ConversationItem({
    required this.conversationId,
    required this.roomId,
    required this.participant,
    required this.unreadCount,
    required this.isMuted,
    required this.updatedAt,
    this.lastMessage,
  });

  final String conversationId;
  final String roomId;
  final ParticipantSummary participant;
  final LastMessagePreview? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationItem &&
          runtimeType == other.runtimeType &&
          conversationId == other.conversationId;

  @override
  int get hashCode => conversationId.hashCode;

  @override
  String toString() => 'ConversationItem('
      'id: $conversationId, '
      'unread: $unreadCount)';
}

// ── Message Item ─────────────────────────────────────────────

@immutable
class MessageItem {
  const MessageItem({
    required this.messageId,
    required this.conversationId,
    required this.roomId,
    required this.senderUserId,
    required this.senderUsername,
    required this.sentAt,
    required this.deliveryState,
    required this.isDeleted,
    this.senderPhotoUrl,
    this.body,
    this.media,
    this.deliveredAt,
    this.readAt,
    this.isUnsent = false,
    this.unsentAt,
    this.unsentByUserId,
  });

  final String messageId;
  final String conversationId;
  final String roomId;
  final String senderUserId;
  final String senderUsername;
  final String? senderPhotoUrl;
  final String? body;
  final MessageMedia? media;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final MessageDeliveryState deliveryState;
  final bool isDeleted;
  final bool isUnsent;
  final DateTime? unsentAt;
  final String? unsentByUserId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageItem &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() => 'MessageItem('
      'id: $messageId, '
      'sender: $senderUsername, '
      'state: ${deliveryState.name})';
}
