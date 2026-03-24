import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/notifiers/conversations_notifier.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/notifiers/message_thread_notifier.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/states/conversations_state.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/states/message_thread_state.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/message_composer.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/thread_sub_widgets.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_manager.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

const Color _teal = AppColors.secondary;

String _computeInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

/// Full message thread screen. Receives a [conversationId] from the router.
///
/// When embedded inside a split-panel layout (e.g. [MessagesScreen]),
/// pass [onBack] to override the default `context.pop()` behavior.
class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({
    super.key,
    required this.conversationId,
    this.onBack,
  });

  final String conversationId;

  /// Optional callback that replaces `context.pop()` when the user taps back.
  /// Used by the messages screen to return to the conversation list on phones.
  final VoidCallback? onBack;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initiateCall(
    WidgetRef ref,
    BuildContext context,
    dynamic conversation,
    CallType callType,
  ) async {
    if (conversation == null) return;
    final participant = conversation.participant;
    final callManager = ref.read(callManagerProvider);
    await callManager.initiateCall(
      targetUserId: participant.userId,
      targetUsername: participant.username,
      targetPhotoUrl: participant.profilePhotoUrl,
      callType: callType,
    );
    if (!context.mounted) return;
    final callState = ref.read(callNotifierProvider);
    final roomName = callState.callInfo?.roomName;
    if (roomName != null) {
      context.push(AppRoutes.call(roomName));
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadState = ref.watch(
      messageThreadNotifierProvider(widget.conversationId),
    );
    final currentUserId = ref.watch(currentUserIdProvider);

    // Resolve participant info from conversations list.
    final conversationsState = ref.watch(conversationsNotifierProvider);
    final conversation = conversationsState is ConversationsLoaded
        ? conversationsState.conversations
            .where((conv) => conv.conversationId == widget.conversationId)
            .firstOrNull
        : null;

    final participantName = conversation?.participant.username ?? 'Chat';
    final participantPhotoUrl = conversation?.participant.profilePhotoUrl;
    final isOnline = conversation?.participant.isOnline ?? false;

    // Set room ID from conversation metadata if thread loaded empty.
    if (conversation != null) {
      ref
          .read(messageThreadNotifierProvider(widget.conversationId).notifier)
          .setRoomId(conversation.roomId);
    }

    final isPartnerTyping =
        threadState is MessageThreadLoaded && threadState.isPartnerTyping;
    final headerStatus = isPartnerTyping
        ? 'Typing...'
        : isOnline
            ? 'Active now'
            : 'Offline';

    ref.listen(
      messageThreadNotifierProvider(widget.conversationId),
      (_, next) {
        if (next is MessageThreadLoaded) _scrollToBottom();
      },
    );

    return Container(
      color: const Color(0xFFF8F1E6),
      child: SafeArea(
        child: Column(
          children: [
            _ThreadHeader(
              participantName: participantName,
              participantPhotoUrl: participantPhotoUrl,
              headerStatus: headerStatus,
              isTyping: isPartnerTyping,
              isOnline: isOnline,
              onBack: widget.onBack ?? () => context.pop(),
              onVoiceCall: () => _initiateCall(ref, context, conversation, CallType.audio),
              onVideoCall: () => _initiateCall(ref, context, conversation, CallType.video),
            ),
            Expanded(
              child: _ThreadBody(
                threadState: threadState,
                currentUserId: currentUserId,
                participantName: participantName,
                participantPhotoUrl: participantPhotoUrl,
                scrollController: _scrollController,
              ),
            ),
            MessageComposer(conversationId: widget.conversationId),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.participantName,
    required this.participantPhotoUrl,
    required this.headerStatus,
    required this.isTyping,
    required this.isOnline,
    required this.onBack,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  final String participantName;
  final String? participantPhotoUrl;
  final String headerStatus;
  final bool isTyping;
  final bool isOnline;
  final VoidCallback onBack;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF7),
        border: Border(bottom: BorderSide(color: Color(0xB3DDD3C2))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.primary),
            tooltip: 'Back to conversations',
          ),
          _HeaderAvatar(
            name: participantName,
            photoUrl: participantPhotoUrl,
            isOnline: isOnline,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: const Color(0xFF18110A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  headerStatus,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: isTyping ? FontWeight.w600 : FontWeight.w500,
                    color: isTyping ? _teal : isOnline ? const Color(0xFF16803C) : const Color(0xFF8D8072),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onVoiceCall,
            icon: const Icon(Icons.phone, size: 18),
            color: AppColors.primary,
            tooltip: 'Voice call',
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          ),
          IconButton(
            onPressed: onVideoCall,
            icon: const Icon(Icons.videocam, size: 18),
            color: _teal,
            tooltip: 'Video call',
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.name,
    required this.photoUrl,
    required this.isOnline,
  });

  final String name;
  final String? photoUrl;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFFFF8EE),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Text(_computeInitials(name),
                  style: AppTypography.label.copyWith(color: AppColors.primary))
              : null,
        ),
        if (isOnline)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                border: Border.all(color: const Color(0xFFFFFBF5), width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Thread body ──────────────────────────────────────────────────────────

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({
    required this.threadState,
    required this.currentUserId,
    required this.participantName,
    required this.participantPhotoUrl,
    required this.scrollController,
  });

  final MessageThreadState threadState;
  final String currentUserId;
  final String participantName;
  final String? participantPhotoUrl;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return switch (threadState) {
      MessageThreadLoading() => const ThreadSkeleton(),
      MessageThreadError(:final exception) => Center(
          child: Text(exception.userMessage,
              style: AppTypography.bodySm.copyWith(color: AppColors.danger)),
        ),
      MessageThreadLoaded(:final messages, :final isPartnerTyping) =>
        messages.isEmpty
            ? EmptyThreadWidget(
                participantName: participantName,
                participantPhotoUrl: participantPhotoUrl,
              )
            : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                itemCount: messages.length + (isPartnerTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && isPartnerTyping) {
                    return TypingBubbleWidget(
                      participantName: participantName,
                      participantPhotoUrl: participantPhotoUrl,
                    );
                  }

                  final message = messages[index];
                  final previousMessage =
                      index > 0 ? messages[index - 1] : null;
                  final nextMessage = index < messages.length - 1
                      ? messages[index + 1]
                      : null;

                  final isGroupStart = previousMessage == null ||
                      previousMessage.senderUserId != message.senderUserId;
                  final isGroupEnd = nextMessage == null ||
                      nextMessage.senderUserId != message.senderUserId;
                  final showDate = previousMessage == null ||
                      isDifferentDay(previousMessage.sentAt, message.sentAt);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDate) DateSeparatorWidget(date: message.sentAt),
                      MessageBubbleWidget(
                        message: message,
                        isMine: message.senderUserId == currentUserId,
                        isGroupStart: isGroupStart,
                        isGroupEnd: isGroupEnd,
                        participantName: participantName,
                        participantPhotoUrl: participantPhotoUrl,
                      ),
                    ],
                  );
                },
              ),
    };
  }
}
