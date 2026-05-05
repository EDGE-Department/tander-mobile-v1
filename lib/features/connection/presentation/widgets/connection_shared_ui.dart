/// Shared UI components for the Connection screen.
///
/// Extracted to keep connection_screen.dart under 400 lines.
/// Contains: StaggeredEntrance, SectionLabel, TabEmptyState, ConnectionErrorState.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Staggered Entrance Animation ────────────────────────────────────

/// Web: initial opacity 0, y 12; animate opacity 1, y 0;
/// delay index * 45ms, duration 220ms, ease [0.16, 1, 0.3, 1]
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    this.delayMilliseconds = 45,
    super.key,
  });

  final int index;
  final Widget child;
  final int delayMilliseconds;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.premiumEase),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: AppCurves.premiumEase),
        );

    Future<void>.delayed(
      Duration(milliseconds: widget.index * widget.delayMilliseconds),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Section Label ───────────────────────────────────────────────────

/// Web: uppercase text-xs font-bold tracking-widest + gradient divider line.
/// E.g. "3 REQUESTS" followed by a fading horizontal rule.
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    required this.count,
    required this.noun,
    this.plural,
    super.key,
  });

  final int count;
  final String noun;
  final String? plural;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 $noun' : '$count ${plural ?? '${noun}s'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.border, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Empty State ─────────────────────────────────────────────────

/// Web: layered concentric circles (3 rings) with gradient tints,
/// icon centered in innermost ring, title + description + optional CTA.
///
/// Outermost: rgba(230,126,34,0.08) -> rgba(15,157,148,0.06)
/// Middle:    rgba(230,126,34,0.14) -> rgba(15,157,148,0.10)
/// Inner:     rgba(230,126,34,0.20) -> rgba(15,157,148,0.15) + icon 36px
class TabEmptyState extends StatelessWidget {
  const TabEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLayeredIcon(),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 280,
            child: Text(
              description,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildActionButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildLayeredIcon() {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring (inset-0)
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [
                  Color(0x14E67E22), // rgba(230,126,34,0.08)
                  Color(0x0F0F9D94), // rgba(15,157,148,0.06)
                ],
              ),
            ),
          ),
          // Middle ring (inset-3 = 12px per side)
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [
                  Color(0x24E67E22), // rgba(230,126,34,0.14)
                  Color(0x1A0F9D94), // rgba(15,157,148,0.10)
                ],
              ),
            ),
          ),
          // Inner ring (inset-6 = 24px per side) with icon
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [
                  Color(0x33E67E22), // rgba(230,126,34,0.20)
                  Color(0x260F9D94), // rgba(15,157,148,0.15)
                ],
              ),
            ),
            child: Center(
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Web: orange gradient button (135deg, #F07020 -> #E67E22)
  Widget _buildActionButton() {
    return GestureDetector(
      onTap: onAction,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
            colors: [Color(0xFFF07020), Color(0xFFE67E22)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40E67E22),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore, size: 16, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(
              actionLabel!,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RefreshableTabEmptyState extends StatelessWidget {
  const RefreshableTabEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.onRefresh,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Future<void> Function() onRefresh;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: TabEmptyState(
                  icon: icon,
                  title: title,
                  description: description,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ConnectionErrorState extends StatelessWidget {
  const ConnectionErrorState({
    required this.title,
    required this.description,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLayeredErrorIcon(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment(-0.7, -1),
                    end: Alignment(0.7, 1),
                    colors: [Color(0xFFF07020), Color(0xFFE67E22)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40E67E22),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Try again',
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayeredErrorIcon() {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.10,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: AppColors.danger.withValues(alpha: 0.08),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.10),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14C0392B),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 38,
                  color: AppColors.danger,
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
