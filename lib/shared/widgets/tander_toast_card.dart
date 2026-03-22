import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Animated card rendering for a single toast notification.
///
/// Handles enter (slide up + fade in), exit (slide right + fade out),
/// auto-dismiss timer, and the countdown progress bar.
///
/// Library-internal — instantiated only by [TanderToastOverlay].
class TanderToastCard extends StatefulWidget {
  const TanderToastCard({required this.entry, super.key});

  /// The toast entry this card renders.
  final ToastEntry entry;

  @override
  State<TanderToastCard> createState() => _TanderToastCardState();
}

class _TanderToastCardState extends State<TanderToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  ToastVariantConfig get _config =>
      toastVariantConfigs[widget.entry.toastData.variant]!;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
    _autoDismissTimer = Timer(widget.entry.duration, _dismiss);
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    // Exit: slide right + fade out.
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController
      ..reset()
      ..forward().then((_) {
        widget.entry.onDismiss(widget.entry);
      });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toastData = widget.entry.toastData;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _config.backgroundColor,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: _config.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              _ToastBody(toastData: toastData, config: _config),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _DismissButton(onTap: _dismiss),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ProgressBar(
                  duration: widget.entry.duration,
                  color: _config.progressColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toast body (icon + text) ──────────────────────────────────────

class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.toastData,
    required this.config,
  });

  final TanderToastData toastData;
  final ToastVariantConfig config;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, size: 20, color: config.iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (toastData.title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(toastData.title!, style: AppTypography.label),
                  ),
                Text(
                  toastData.message,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted,
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

// ── Dismiss "X" button ────────────────────────────────────────────

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: AppSpacing.lg,
        height: AppSpacing.lg,
        child: Center(
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Progress bar (auto-dismiss countdown) ─────────────────────────

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.duration,
    required this.color,
  });

  final Duration duration;
  final Color color;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  static const double _barHeight = 2;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _barHeight,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (_, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 1.0 - _progressController.value,
          child: ColoredBox(color: widget.color),
        ),
      ),
    );
  }
}
