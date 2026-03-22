import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/notifiers/tandy_notifier.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/states/tandy_state.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_composer.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_empty_state.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_message_thread.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_sidebar.dart';

/// Hub screen for the Tandy AI module.
///
/// Shows a sidebar on wide screens and either the empty state (with
/// mood check-in and features grid) or the chat message thread.
class TandyScreen extends ConsumerStatefulWidget {
  const TandyScreen({super.key});

  @override
  ConsumerState<TandyScreen> createState() => _TandyScreenState();
}

class _TandyScreenState extends ConsumerState<TandyScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    ref.read(tandyNotifierProvider.notifier).sendMessage(text);
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _handleClear() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear conversation'),
        content:
            const Text('Clear your conversation with Tandy?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(tandyNotifierProvider.notifier).clearConversation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tandyState = ref.watch(tandyNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    ref.listen<TandyState>(tandyNotifierProvider, (previous, next) {
      if (next is TandyLoaded && previous is TandyLoaded) {
        if (next.messages.length > previous.messages.length) {
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Row(
        children: <Widget>[
          // Sidebar on wide screens
          if (isWide)
            SizedBox(
              width: 284,
              child: TandySidebar(
                messageCount: tandyState is TandyLoaded
                    ? tandyState.messages.length
                    : 0,
                statusLabel: tandyState is TandyLoaded && tandyState.isSending
                    ? 'Replying\u2026'
                    : 'Ready to support you',
                onChatTap: () => _focusNode.requestFocus(),
                onBreatheTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.breathe),
                onMeditateTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.meditate),
                onSupportTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.support),
                onClearTap: _handleClear,
              ),
            ),

          // Main content
          Expanded(
            child: Column(
              children: <Widget>[
                // Message area
                Expanded(
                  child: _buildBody(tandyState),
                ),

                // Send error
                if (tandyState is TandyLoaded &&
                    tandyState.sendError != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    color: AppColors.dangerLight,
                    child: Text(
                      tandyState.sendError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Composer
                if (tandyState is TandyLoaded)
                  TandyComposer(
                    controller: _inputController,
                    focusNode: _focusNode,
                    isSending: tandyState.isSending,
                    showSuggestions: tandyState.showEmptyState,
                    suggestions: tandyState.greeting.suggestions,
                    onSend: _handleSend,
                    onSuggestionTap: (suggestion) {
                      _inputController.text = suggestion;
                      _focusNode.requestFocus();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TandyState tandyState) {
    return switch (tandyState) {
      TandyLoading() => const Center(
          child: CircularProgressIndicator(color: kTandyOrange),
        ),
      TandyError(:final exception) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  exception.userMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textBody),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref
                      .read(tandyNotifierProvider.notifier)
                      .loadConversation(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      TandyLoaded(:final showEmptyState) when showEmptyState =>
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kThreadMaxWidth),
              child: TandyEmptyState(
                greeting: (tandyState as TandyLoaded).greeting.greeting,
                onMoodSelect: (chatMessage) {
                  _inputController.text = chatMessage;
                  _focusNode.requestFocus();
                },
                onBreathingTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.breathe),
                onMeditationTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.meditate),
                onChatTap: () => _focusNode.requestFocus(),
                onWellnessTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.support),
              ),
            ),
          ),
        ),
      TandyLoaded() => TandyMessageThread(
          messages: (tandyState as TandyLoaded).messages,
          isSending: (tandyState as TandyLoaded).isSending,
          scrollController: _scrollController,
        ),
    };
  }
}
