import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/screens/message_thread_screen.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/conversation_list_states.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/messages_sidebar_widgets.dart';

const double _desktopBreakpoint = 1024;
const double _sidebarMaxWidth = 392;

/// Main Messages screen with embedded split-panel messaging.
///
/// **Mobile** (width < 1024): conversation list and thread panel swap
/// in-place using state-based visibility. No GoRouter navigation.
///
/// **Desktop** (width >= 1024): sidebar 392 px + thread flex-1 side by side.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String? _activeConversationId;

  void _selectConversation(String conversationId) {
    setState(() => _activeConversationId = conversationId);
  }

  void _clearSelection() {
    setState(() => _activeConversationId = null);
  }

  @override
  Widget build(BuildContext context) {
    final isThreadOpen = _activeConversationId != null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5ECE2), Color(0xFFEDE1D2)],
        ),
      ),
      child: Stack(
        children: [
          const _AtmosphericOverlays(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

                  if (isDesktop) {
                    return _DesktopLayout(
                      activeConversationId: _activeConversationId,
                      onSelectConversation: _selectConversation,
                      onClearSelection: _clearSelection,
                    );
                  }

                  return _MobileLayout(
                    activeConversationId: _activeConversationId,
                    isThreadOpen: isThreadOpen,
                    onSelectConversation: _selectConversation,
                    onClearSelection: _clearSelection,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Atmospheric overlays ------------------------------------------------

class _AtmosphericOverlays extends StatelessWidget {
  const _AtmosphericOverlays();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _RadialOverlayPainter()),
      ),
    );
  }
}

class _RadialOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // White glow at 14 %, 10 %
    _paintRadial(
      canvas,
      center: Offset(size.width * 0.14, size.height * 0.10),
      radius: size.width * 0.18,
      color: const Color(0x9EFFFFFF),
    );
    // Teal glow at 82 %, 12 %
    _paintRadial(
      canvas,
      center: Offset(size.width * 0.82, size.height * 0.12),
      radius: size.width * 0.18,
      color: const Color(0x140F9D94),
    );
    // Orange glow at 78 %, 82 %
    _paintRadial(
      canvas,
      center: Offset(size.width * 0.78, size.height * 0.82),
      radius: size.width * 0.16,
      color: const Color(0x1EE67E22),
    );
  }

  void _paintRadial(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---- Mobile layout -------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.activeConversationId,
    required this.isThreadOpen,
    required this.onSelectConversation,
    required this.onClearSelection,
  });

  final String? activeConversationId;
  final bool isThreadOpen;
  final ValueChanged<String> onSelectConversation;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    if (isThreadOpen) {
      return _ThreadPanel(
        conversationId: activeConversationId!,
        onBack: onClearSelection,
      );
    }

    return _SidebarPanel(
      activeConversationId: activeConversationId,
      onSelectConversation: onSelectConversation,
    );
  }
}

// ---- Desktop layout ------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.activeConversationId,
    required this.onSelectConversation,
    required this.onClearSelection,
  });

  final String? activeConversationId;
  final ValueChanged<String> onSelectConversation;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _sidebarMaxWidth),
          child: _SidebarPanel(
            activeConversationId: activeConversationId,
            onSelectConversation: onSelectConversation,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: activeConversationId != null
              ? _ThreadPanel(
                  conversationId: activeConversationId!,
                  onBack: onClearSelection,
                )
              : const MessagesWelcomePlaceholder(),
        ),
      ],
    );
  }
}

// ---- Sidebar panel (visual container) ------------------------------------

class _SidebarPanel extends StatelessWidget {
  const _SidebarPanel({
    required this.activeConversationId,
    required this.onSelectConversation,
  });

  final String? activeConversationId;
  final ValueChanged<String> onSelectConversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderXl,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF8FFFDF9), Color(0xF8FFF8F0)],
        ),
        border: Border.all(color: const Color(0xD9DCCEBC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14764F21),
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: MessagesSidebarContent(
        activeConversationId: activeConversationId,
        onSelectConversation: onSelectConversation,
      ),
    );
  }
}

// ---- Thread panel (visual container) -------------------------------------

class _ThreadPanel extends StatelessWidget {
  const _ThreadPanel({
    required this.conversationId,
    required this.onBack,
  });

  final String conversationId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderXl,
        color: const Color(0xCCFFFBF6),
        border: Border.all(color: const Color(0xD9DCCEBC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14764F21),
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: MessageThreadScreen(
        key: ValueKey(conversationId),
        conversationId: conversationId,
        onBack: onBack,
      ),
    );
  }
}
