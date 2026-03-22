import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/notifiers/tandy_notifier.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/states/tandy_state.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_breathing_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_composer.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_meditation_panel.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_message_thread.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_support_panel.dart';

/// Full-screen Tandy chat — navigated to from the hub.
///
/// Features a premium header with back nav, embedded wellness panel
/// overlays, and the full chat interface.
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
          Column(
            children: <Widget>[
              // Header
              _ChatHeader(
                onBack: () => context.pop(),
                onClear: _handleClear,
              ),

              // Feature chips bar
              _FeatureChipsBar(
                onBreatheTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.breathe),
                onMeditateTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.meditate),
                onSupportTap: () => ref
                    .read(tandyNotifierProvider.notifier)
                    .setActivePanel(TandyActivePanel.support),
              ),

              // Messages
              Expanded(
                child: tandyState is TandyLoaded
                    ? TandyMessageThread(
                        messages: tandyState.messages,
                        isSending: tandyState.isSending,
                        scrollController: _scrollController,
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: kTandyOrange,
                        ),
                      ),
              ),

              // Error bar
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
                  showSuggestions: false,
                  suggestions: const <String>[],
                  onSend: _handleSend,
                  onSuggestionTap: (_) {},
                ),
            ],
          ),

          // Wellness panel overlay
          if (tandyState is TandyLoaded &&
              tandyState.activePanel != null)
            _buildPanelOverlay(tandyState.activePanel!),
        ],
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
        TandyActivePanel.psychiatrist => TandySupportPanel(
            onClose: notifier.closePanel,
            onOpenPsychiatrist: () {},
          ),
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.onBack,
    required this.onClear,
  });

  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF0FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: <Widget>[
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFEF0E0), Color(0xFFFDE8CC)],
              ),
              border: Border.all(
                color: kTandyOrange.withAlpha(77),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: kTandyOrange, size: 22),
            ),
          ),
          const SizedBox(width: 11),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tandy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textStrong,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online \u00B7 Your companion',
                      style: TextStyle(
                        fontSize: 12,
                        color: kTandyGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Clear button
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline, size: 16),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Chips Bar ──────────────────────────────────────────────────

class _FeatureChipsBar extends StatelessWidget {
  const _FeatureChipsBar({
    required this.onBreatheTap,
    required this.onMeditateTap,
    required this.onSupportTap,
  });

  final VoidCallback onBreatheTap;
  final VoidCallback onMeditateTap;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xF5FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _FeatureChip(
            label: 'Breathe',
            icon: Icons.air,
            color: kTandyTeal,
            onTap: onBreatheTap,
          ),
          const SizedBox(width: 8),
          _FeatureChip(
            label: 'Meditate',
            icon: Icons.self_improvement,
            color: kTandyPurple,
            onTap: onMeditateTap,
          ),
          const SizedBox(width: 8),
          _FeatureChip(
            label: 'Support',
            icon: Icons.person_outline,
            color: kTandyBlue,
            onTap: onSupportTap,
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
      onPressed: onTap,
      side: BorderSide(color: color.withAlpha(55)),
      backgroundColor: color.withAlpha(20),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
