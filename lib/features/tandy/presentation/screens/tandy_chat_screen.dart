/// Full-screen Tandy chat -- navigated to from the hub.
///
/// Matches web tandy-chat-page.tsx:
/// - Premium header with back nav, Tandy avatar, online status, clear button
/// - Feature chips bar (Breathe/Meditate/Support)
/// - Full chat interface with grouped bubbles
/// - Wellness panel overlays
/// - Composer footer with send button
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/notifiers/tandy_notifier.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/states/tandy_state.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_breathing_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_chat_header.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_composer.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_meditation_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_message_thread.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_psychiatrist_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_support_panel.dart';
import 'package:tander_flutter_v3/shared/widgets/centered_max_width.dart';

class TandyChatScreen extends ConsumerStatefulWidget {
  const TandyChatScreen({super.key});

  @override
  ConsumerState<TandyChatScreen> createState() => _TandyChatScreenState();
}

class _TandyChatScreenState extends ConsumerState<TandyChatScreen> {
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
        content: const Text('Clear your conversation with Tandy?'),
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

    ref.listen<TandyState>(tandyNotifierProvider, (previous, next) {
      if (next is TandyLoaded && previous is TandyLoaded) {
        if (next.messages.length > previous.messages.length) {
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: <Widget>[
          // Tablet: keep the chat in a centered reading column.
          CenteredMaxWidth(
            maxWidth: 760,
            child: Column(
              children: <Widget>[
                // Header
                TandyChatHeader(
                  onBack: () => context.pop(),
                  onClear: _handleClear,
                ),

                // Feature chips bar
                TandyChatChipsBar(
                  onBreatheTap: () => _openPanel(TandyActivePanel.breathe),
                  onMeditateTap: () => _openPanel(TandyActivePanel.meditate),
                  onSupportTap: () => _openPanel(TandyActivePanel.support),
                ),

                // Messages
                Expanded(
                  child: switch (tandyState) {
                    TandyLoaded(:final messages, :final isSending) =>
                      TandyMessageThread(
                        messages: messages,
                        isSending: isSending,
                        scrollController: _scrollController,
                      ),
                    TandyError(:final exception) => _buildErrorState(exception),
                    TandyLoading() => const Center(
                      child: CircularProgressIndicator(color: kTandyOrange),
                    ),
                  },
                ),

                // Error bar
                if (tandyState is TandyLoaded && tandyState.sendError != null)
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

                // Breathing suggestion chip
                if (tandyState is TandyLoaded &&
                    tandyState.suggestBreathingPanel)
                  _buildBreathingSuggestion(),

                // Composer
                if (tandyState is TandyLoaded)
                  TandyComposer(
                    controller: _inputController,
                    focusNode: _focusNode,
                    isSending: tandyState.isSending,
                    showSuggestions: false,
                    suggestions: const <String>[],
                    onSend: _handleSend,
                    onSuggestionTap: (_) {},
                  ),
              ],
            ),
          ),

          // Wellness panel overlay
          if (tandyState is TandyLoaded && tandyState.activePanel != null)
            _buildPanelOverlay(tandyState.activePanel!),
        ],
      ),
    );
  }

  Widget _buildBreathingSuggestion() {
    final notifier = ref.read(tandyNotifierProvider.notifier);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F5F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0F9D94).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.air_rounded, color: Color(0xFF0F9D94), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'How about a short breathing exercise?',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF1A5F5B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              notifier.dismissBreathingSuggestion();
              notifier.setActivePanel(TandyActivePanel.breathe);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F9D94),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: notifier.dismissBreathingSuggestion,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF0F9D94),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppException exception) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              exception.userMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textBody),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(tandyNotifierProvider.notifier).loadConversation(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelOverlay(TandyActivePanel panel) {
    final notifier = ref.read(tandyNotifierProvider.notifier);
    return Positioned.fill(
      child: switch (panel) {
        TandyActivePanel.breathe => TandyBreathingPanel(
          onClose: notifier.closePanel,
        ),
        TandyActivePanel.meditate => TandyMeditationPanel(
          onClose: notifier.closePanel,
        ),
        TandyActivePanel.support => TandySupportPanel(
          onClose: notifier.closePanel,
          onOpenPsychiatrist: () =>
              notifier.setActivePanel(TandyActivePanel.psychiatrist),
        ),
        TandyActivePanel.psychiatrist => TandyPsychiatristPanel(
          onClose: notifier.closePanel,
          onBack: () => notifier.setActivePanel(TandyActivePanel.support),
        ),
      },
    );
  }

  void _openPanel(TandyActivePanel panel) {
    ref.read(tandyNotifierProvider.notifier).setActivePanel(panel);
  }
}
