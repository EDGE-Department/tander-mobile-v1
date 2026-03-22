import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

/// Sealed state hierarchy for the message thread UI.
sealed class MessageThreadState {
  const MessageThreadState();
}

/// Initial loading -- messages are being fetched for the first time.
final class MessageThreadLoading extends MessageThreadState {
  const MessageThreadLoading();
}

/// Messages loaded successfully.
final class MessageThreadLoaded extends MessageThreadState {
  const MessageThreadLoaded({
    required this.messages,
    this.isPartnerTyping = false,
    this.isSending = false,
    this.isSendingMedia = false,
  });

  /// All messages in the thread, oldest first.
  final List<MessageItem> messages;

  /// Whether the other participant is currently typing.
  final bool isPartnerTyping;

  /// Whether a text message is currently being sent.
  final bool isSending;

  /// Whether an image or voice message is currently being sent.
  final bool isSendingMedia;

  MessageThreadLoaded copyWith({
    List<MessageItem>? messages,
    bool? isPartnerTyping,
    bool? isSending,
    bool? isSendingMedia,
  }) {
    return MessageThreadLoaded(
      messages: messages ?? this.messages,
      isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      isSending: isSending ?? this.isSending,
      isSendingMedia: isSendingMedia ?? this.isSendingMedia,
    );
  }
}

/// Message thread fetch failed with a typed exception.
final class MessageThreadError extends MessageThreadState {
  const MessageThreadError({required this.exception});

  final AppException exception;
}
