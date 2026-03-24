/// Hub screen for the Tandy AI module.
///
/// Matches web tandy-page.tsx:
/// - Phone: no sidebar, mobile header visible, full-width chat, mobile
///   feature bar at bottom, quick-prompt chips horizontal scroll.
/// - Tablet (>=1024): sidebar 284px LEFT, chat area flex-1 RIGHT, no
///   mobile header.
///
/// Uses LayoutBuilder for phone vs tablet breakpoint.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/notifiers/tandy_notifier.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/states/tandy_state.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_breathing_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constellation_bg.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_composer.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_meditation_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_psychiatrist_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_support_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_empty_state.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_message_thread.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_mobile_bar.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_sidebar.dart';

/// Tablet breakpoint matching the web's `lg:` (1024px).
const double _kTabletBreakpoint = 1024;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= _kTabletBreakpoint;
          return _buildLayout(tandyState, isTablet: isTablet);
        },
      ),
    );
  }

  Widget _buildLayout(TandyState tandyState, {required bool isTablet}) {
    return Row(
      children: <Widget>[
        // Sidebar on tablet (web: hidden lg:flex, width 284)
        if (isTablet)
          SizedBox(
            width: 284,
            child: TandySidebar(
              messageCount: tandyState is TandyLoaded
                  ? tandyState.messages.length
                  : 0,
              statusLabel: _resolveStatusLabel(tandyState),
              onChatTap: () {
                ref.read(tandyNotifierProvider.notifier).closePanel();
                _focusNode.requestFocus();
              },
              onBreatheTap: () => _openPanel(TandyActivePanel.breathe),
              onMeditateTap: () => _openPanel(TandyActivePanel.meditate),
              onSupportTap: () => _openPanel(TandyActivePanel.support),
              onClearTap: _handleClear,
            ),
          ),

        // Main content area — Stack so panels overlay the chat, not the sidebar
        Expanded(
          child: Stack(
            children: [
              // Constellation background
              const Positioned.fill(child: TandyConstellationBg()),
              Column(
                children: <Widget>[
                  // Mobile header (web: flex lg:hidden)
                  if (!isTablet) const TandyMobileHeader(),

                  // Message area
                  Expanded(child: _buildBody(tandyState)),

                  // Send error bar
                  if (tandyState is TandyLoaded && tandyState.sendError != null)
                    _buildErrorBar(tandyState.sendError!),

                  // Mobile feature bar (web: lg:hidden)
                  if (!isTablet && tandyState is TandyLoaded)
                    TandyMobileFeatureBar(
                      onChatTap: () {
                        ref.read(tandyNotifierProvider.notifier).closePanel();
                        _focusNode.requestFocus();
                      },
                      onBreatheTap: () => _openPanel(TandyActivePanel.breathe),
                      onMeditateTap: () =>
                          _openPanel(TandyActivePanel.meditate),
                      onSupportTap: () =>
                          _openPanel(TandyActivePanel.support),
                      onClearTap: _handleClear,
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
            // Panel overlay — covers main content area only, sidebar stays visible
            if (tandyState is TandyLoaded && tandyState.activePanel != null)
              _buildPanelOverlay(tandyState.activePanel!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(TandyState tandyState) {
    return switch (tandyState) {
      TandyLoading() => const Center(
          child: CircularProgressIndicator(color: kTandyOrange),
        ),
      TandyError(:final exception) => _buildErrorState(exception),
      final TandyLoaded loaded when loaded.showEmptyState =>
        _buildEmptyState(loaded),
      TandyLoaded(
        :final messages,
        :final isSending,
      ) =>
        TandyMessageThread(
          messages: messages,
          isSending: isSending,
          scrollController: _scrollController,
        ),
    };
  }

  Widget _buildEmptyState(TandyLoaded loadedState) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kThreadMaxWidth),
          child: TandyEmptyState(
            greeting: loadedState.greeting.greeting,
            onMoodSelect: (chatMessage) {
              _inputController.text = chatMessage;
              _focusNode.requestFocus();
            },
            onBreathingTap: () => _openPanel(TandyActivePanel.breathe),
            onMeditationTap: () =>
                _openPanel(TandyActivePanel.meditate),
            onChatTap: () => _focusNode.requestFocus(),
            onWellnessTap: () => _openPanel(TandyActivePanel.support),
          ),
        ),
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.danger,
            ),
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
    );
  }

  Widget _buildErrorBar(String errorMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.dangerLight,
      child: Text(
        errorMessage,
        style: const TextStyle(color: AppColors.danger, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  void _openPanel(TandyActivePanel panel) {
    ref.read(tandyNotifierProvider.notifier).setActivePanel(panel);
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

  String _resolveStatusLabel(TandyState tandyState) {
    if (tandyState is TandyLoaded && tandyState.isSending) {
      return 'Replying\u2026';
    }
    return 'Ready to support you';
  }
}
