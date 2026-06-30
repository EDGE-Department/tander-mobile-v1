import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/realtime/stomp_client_manager.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/messaging/data/datasources/messaging_stomp_datasource.dart';
import 'package:tander_flutter_v3/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/notifiers/conversations_notifier.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/states/message_thread_state.dart';

/// Typing cooldown to avoid spamming the STOMP destination.
const Duration _typingCooldown = Duration(seconds: 3);

/// Auto-clear typing indicator after this duration without follow-up.
const Duration _typingAutoClear = Duration(seconds: 5);

// ─── Family provider keyed on conversationId ───────────────────────────

final messageThreadNotifierProvider = NotifierProvider.family
    .autoDispose<MessageThreadNotifier, MessageThreadState, String>(
      MessageThreadNotifier.new,
    );

// ─── Notifier ──────────────────────────────────────────────────────────

/// Manages a single message thread: STOMP subscriptions, sending, typing,
/// delivery receipts, and read receipts.
///
/// Keyed by [conversationId]. Each thread screen gets its own instance.
final class MessageThreadNotifier
    extends AutoDisposeFamilyNotifier<MessageThreadState, String> {
  // `late`, not `late final`: Notifier.build() re-runs on invalidate/refresh
  // (incl. config changes like font-scale); re-assigning a final field throws
  // LateInitializationError.
  late MessagingRepository _repository;
  late MessagingStompDatasource _stompDatasource;
  late String _currentUserId;
  late String _conversationId;
  String _roomId = '';

  final List<StompUnsubscribeCallback> _stompTeardowns = [];
  Timer? _typingCooldownTimer;
  Timer? _typingAutoClearTimer;

  static const String _tag = 'MessageThreadNotifier';

  @override
  MessageThreadState build(String conversationId) {
    _repository = ref.read(messagingRepositoryProvider);
    _stompDatasource = ref.read(messagingStompDatasourceProvider);
    _currentUserId = ref.read(currentUserIdProvider);
    _conversationId = conversationId;

    ref.onDispose(_cleanup);

    Future.microtask(() => _initialize(conversationId));

    return const MessageThreadLoading();
  }

  // -----------------------------------------------------------------------
  // Initialization
  // -----------------------------------------------------------------------

  Future<void> _initialize(String conversationId) async {
    await _loadMessages(conversationId);
    _markRead();
    _subscribeToStompTopics();
  }

  Future<void> _loadMessages(String conversationId) async {
    final fetchResult = await _repository.fetchMessages(
      conversationId: conversationId,
    );

    fetchResult.when(
      success: (messages) {
        if (messages.isNotEmpty) {
          _roomId = messages.first.roomId;
        }
        state = MessageThreadLoaded(messages: messages);
      },
      failure: (exception) {
        state = MessageThreadError(exception: exception);
        AppLogger.error(
          'Failed to load messages',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  /// Pull-to-refresh: fetch the latest messages without dropping transient
  /// state (typing flags, send-in-flight). Returns `true` on success, `false`
  /// on failure so the UI can decide whether to show a SnackBar.
  Future<bool> refreshMessages() async {
    final fetchResult = await _repository.fetchMessages(
      conversationId: _conversationId,
    );

    return fetchResult.when(
      success: (messages) {
        if (messages.isNotEmpty) {
          _roomId = messages.first.roomId;
        }
        final current = state;
        state = current is MessageThreadLoaded
            ? current.copyWith(messages: messages)
            : MessageThreadLoaded(messages: messages);
        _markRead();
        return true;
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to refresh messages',
          operation: _tag,
          error: exception,
        );
        return false;
      },
    );
  }

  // -----------------------------------------------------------------------
  // STOMP subscriptions
  // -----------------------------------------------------------------------

  void _subscribeToStompTopics() {
    _stompTeardowns.add(
      _stompDatasource.subscribeToConversation(
        _conversationId,
        roomId: _roomId,
        onMessage: _onStompMessage,
      ),
    );

    _stompTeardowns.add(
      _stompDatasource.subscribeToTyping(
        _conversationId,
        onTyping: ({required bool isTyping, required String usrId}) {
          _onStompTyping(isTyping: isTyping, userId: usrId);
        },
      ),
    );

    _stompTeardowns.add(
      _stompDatasource.subscribeToDelivered(
        _conversationId,
        onDelivered: _onStompDelivered,
      ),
    );

    _stompTeardowns.add(
      _stompDatasource.subscribeToRead(_conversationId, onRead: _onStompRead),
    );
  }

  void _onStompMessage(MessageItem message) {
    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    // Deduplicate.
    final alreadyExists = currentState.messages.any(
      (existing) => existing.messageId == message.messageId,
    );
    if (alreadyExists) return;

    final updatedMessages = [...currentState.messages, message];
    state = currentState.copyWith(
      messages: updatedMessages,
      isPartnerTyping: false,
    );

    final isOwnMessage = message.senderUserId == _currentUserId;
    if (!isOwnMessage) {
      _stompDatasource.sendDeliveryReceipt(
        messageId: message.messageId,
        conversationId: _conversationId,
      );
      _markRead();
    }

    // Refresh the conversation list to update previews.
    ref.read(conversationsNotifierProvider.notifier).refreshSilently();
  }

  void _onStompTyping({required bool isTyping, required String userId}) {
    if (userId == _currentUserId) return;

    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    state = currentState.copyWith(isPartnerTyping: isTyping);

    if (isTyping) {
      _typingAutoClearTimer?.cancel();
      _typingAutoClearTimer = Timer(_typingAutoClear, () {
        final latestState = state;
        if (latestState is MessageThreadLoaded) {
          state = latestState.copyWith(isPartnerTyping: false);
        }
      });
    }
  }

  void _onStompDelivered(String messageId) {
    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    final updatedMessages = currentState.messages.map((message) {
      if (message.messageId == messageId &&
          message.deliveryState == MessageDeliveryState.sent) {
        return MessageItem(
          messageId: message.messageId,
          conversationId: message.conversationId,
          roomId: message.roomId,
          senderUserId: message.senderUserId,
          senderUsername: message.senderUsername,
          senderPhotoUrl: message.senderPhotoUrl,
          body: message.body,
          media: message.media,
          sentAt: message.sentAt,
          deliveredAt: DateTime.now(),
          readAt: message.readAt,
          deliveryState: MessageDeliveryState.delivered,
          isDeleted: message.isDeleted,
        );
      }
      return message;
    }).toList();

    state = currentState.copyWith(messages: updatedMessages);
  }

  void _onStompRead({required String readByUserId}) {
    if (readByUserId == _currentUserId) return;

    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    // Mark all of our sent messages as read.
    final updatedMessages = currentState.messages.map((message) {
      if (message.senderUserId == _currentUserId &&
          message.deliveryState != MessageDeliveryState.read) {
        return MessageItem(
          messageId: message.messageId,
          conversationId: message.conversationId,
          roomId: message.roomId,
          senderUserId: message.senderUserId,
          senderUsername: message.senderUsername,
          senderPhotoUrl: message.senderPhotoUrl,
          body: message.body,
          media: message.media,
          sentAt: message.sentAt,
          deliveredAt: message.deliveredAt,
          readAt: DateTime.now(),
          deliveryState: MessageDeliveryState.read,
          isDeleted: message.isDeleted,
        );
      }
      return message;
    }).toList();

    state = currentState.copyWith(messages: updatedMessages);
    ref.read(conversationsNotifierProvider.notifier).refreshSilently();
  }

  // -----------------------------------------------------------------------
  // Send actions
  // -----------------------------------------------------------------------

  /// Sends a text message.
  Future<void> sendTextMessage(String body) async {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) return;

    final currentState = state;
    if (currentState is! MessageThreadLoaded || currentState.isSending) return;

    state = currentState.copyWith(isSending: true);

    final sendResult = await _repository.sendTextMessage(
      conversationId: _conversationId,
      body: trimmedBody,
    );

    final latestState = state;
    if (latestState is! MessageThreadLoaded) return;

    sendResult.when(
      success: (sentMessage) {
        _appendMessage(latestState, sentMessage);
        state = (state as MessageThreadLoaded).copyWith(isSending: false);
        ref.read(conversationsNotifierProvider.notifier).refreshSilently();
      },
      failure: (exception) {
        state = latestState.copyWith(isSending: false);
        AppLogger.error(
          'Failed to send text message',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  /// Sends an image message from a local file path.
  Future<void> sendImageMessage({
    required String filePath,
    required String fileName,
  }) async {
    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    state = currentState.copyWith(isSendingMedia: true);

    final sendResult = await _repository.sendImageMessage(
      conversationId: _conversationId,
      filePath: filePath,
      fileName: fileName,
    );

    final latestState = state;
    if (latestState is! MessageThreadLoaded) return;

    sendResult.when(
      success: (sentMessage) {
        _appendMessage(latestState, sentMessage);
        state = (state as MessageThreadLoaded).copyWith(isSendingMedia: false);
        ref.read(conversationsNotifierProvider.notifier).refreshSilently();
      },
      failure: (exception) {
        state = latestState.copyWith(isSendingMedia: false);
        AppLogger.error(
          'Failed to send image message',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  /// Sends a voice message from a local file path.
  Future<void> sendVoiceMessage({
    required String filePath,
    required String fileName,
    required int durationSeconds,
  }) async {
    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    state = currentState.copyWith(isSendingMedia: true);

    final sendResult = await _repository.sendVoiceMessage(
      conversationId: _conversationId,
      filePath: filePath,
      fileName: fileName,
      durationSeconds: durationSeconds,
    );

    final latestState = state;
    if (latestState is! MessageThreadLoaded) return;

    sendResult.when(
      success: (sentMessage) {
        _appendMessage(latestState, sentMessage);
        state = (state as MessageThreadLoaded).copyWith(isSendingMedia: false);
        ref.read(conversationsNotifierProvider.notifier).refreshSilently();
      },
      failure: (exception) {
        state = latestState.copyWith(isSendingMedia: false);
        AppLogger.error(
          'Failed to send voice message',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Message deletion
  // -----------------------------------------------------------------------

  /// Unsend a message (delete for everyone). Sender-only, 1-hour limit.
  /// Optimistic: updates UI immediately, rolls back on failure.
  Future<void> unsendMessage(String messageId) async {
    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    // Optimistic update — mark as unsent immediately
    final updated = currentState.messages.map((m) {
      if (m.messageId == messageId) {
        return MessageItem(
          messageId: m.messageId,
          conversationId: m.conversationId,
          roomId: m.roomId,
          senderUserId: m.senderUserId,
          senderUsername: m.senderUsername,
          senderPhotoUrl: m.senderPhotoUrl,
          body: null,
          media: null,
          sentAt: m.sentAt,
          deliveryState: m.deliveryState,
          isDeleted: true,
          isUnsent: true,
          unsentAt: DateTime.now(),
          unsentByUserId: m.senderUserId,
        );
      }
      return m;
    }).toList();
    state = currentState.copyWith(messages: updated);

    // Fire API call in background
    final result = await _repository.unsendMessage(messageId: messageId);
    result.when(
      success: (_) {
        ref.read(conversationsNotifierProvider.notifier).refreshSilently();
      },
      failure: (exception) {
        // Roll back on failure
        state = currentState;
        AppLogger.error(
          'Failed to unsend message',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  /// Hide a message for the current user only (delete for me).
  /// Optimistic: removes from view immediately, rolls back on failure.
  Future<void> hideMessageForUser(String messageId) async {
    final currentState = state;
    if (currentState is! MessageThreadLoaded) return;

    // Optimistic update — remove from view immediately
    final updated = currentState.messages
        .where((m) => m.messageId != messageId)
        .toList();
    state = currentState.copyWith(messages: updated);

    // Fire API call in background
    final result = await _repository.hideMessageForUser(messageId: messageId);
    result.when(
      success: (_) {
        ref.read(conversationsNotifierProvider.notifier).refreshSilently();
      },
      failure: (exception) {
        // Roll back on failure
        state = currentState;
        AppLogger.error(
          'Failed to hide message',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Typing indicator
  // -----------------------------------------------------------------------

  /// Notify the server that the user is typing, rate-limited to one send
  /// per [_typingCooldown].
  void notifyTyping() {
    if (_typingCooldownTimer?.isActive ?? false) return;

    _stompDatasource.sendTypingIndicator(_conversationId, isTyping: true);

    _typingCooldownTimer = Timer(_typingCooldown, () {
      _stompDatasource.sendTypingIndicator(_conversationId, isTyping: false);
    });
  }

  // -----------------------------------------------------------------------
  // Room ID setter (for cases where messages were empty on load)
  // -----------------------------------------------------------------------

  /// Sets the room ID externally (e.g. from the conversation item).
  void setRoomId(String roomId) {
    if (_roomId.isNotEmpty) return;
    _roomId = roomId;
    _subscribeToStompTopics();
  }

  /// Exposes the current room ID for the composer widget.
  String get roomId => _roomId;

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  void _markRead() {
    _repository.markConversationRead(conversationId: _conversationId);
    _stompDatasource.sendReadReceipt(conversationId: _conversationId);
  }

  void _appendMessage(MessageThreadLoaded currentState, MessageItem message) {
    final alreadyExists = currentState.messages.any(
      (existing) => existing.messageId == message.messageId,
    );
    if (alreadyExists) return;

    final updatedMessages = [...currentState.messages, message];
    state = currentState.copyWith(messages: updatedMessages);
  }

  void _cleanup() {
    for (final teardown in _stompTeardowns) {
      teardown();
    }
    _stompTeardowns.clear();
    _typingCooldownTimer?.cancel();
    _typingAutoClearTimer?.cancel();
  }
}
