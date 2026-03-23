/// Action buttons, ghost card, progress dots, and remaining badge
/// for the discover card stack.
///
/// Pixel-perfect port of the action row from tander-web discover-page.tsx.
/// Extracted from discover_screen.dart to keep files under 400 lines.
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Action buttons row ──────────────────────────────────────────────────
// Web: gap-5, Pass 60x60, Connect 76x76 gradient, Profile 60x60

class DiscoverActionButtons extends StatelessWidget {
  const DiscoverActionButtons({
    required this.candidate,
    required this.onPass,
    required this.onLike,
    required this.onViewProfile,
    super.key,
  });

  final DiscoveryCandidate candidate;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CircleActionButton(
            icon: PhosphorIconsBold.x,
            iconColor: AppColors.danger,
            size: 60,
            label: 'Pass',
            semanticLabel: 'Pass on ${candidate.firstName}',
            onTap: onPass,
          ),
          const SizedBox(width: 20),
          _CircleActionButton(
            icon: PhosphorIconsFill.heart,
            iconColor: AppColors.textInverse,
            size: 76,
            label: 'Connect',
            labelColor: AppColors.primary,
            labelWeight: FontWeight.w700,
            semanticLabel: 'Connect with ${candidate.firstName}',
            isPrimary: true,
            onTap: onLike,
          ),
          const SizedBox(width: 20),
          _CircleActionButton(
            icon: PhosphorIconsRegular.info,
            iconColor: AppColors.secondary,
            size: 60,
            label: 'Profile',
            semanticLabel: 'View ${candidate.firstName} full profile',
            onTap: onViewProfile,
          ),
        ],
      ),
    );
  }
}

// ── Circle action button ────────────────────────────────────────────────
// Web: Pass/Profile: bg #fff, border 2.5px #E8E3DA, shadow-md
// Web: Connect: gradient #F07020 -> #E67E22, shadow 0 6px 20px

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.iconColor,
    required this.size,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.labelColor = AppColors.textMuted,
    this.labelWeight = FontWeight.w600,
    this.isPrimary = false,
  });

  final IconData icon;
  final Color iconColor;
  final double size;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final Color labelColor;
  final FontWeight labelWeight;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: semanticLabel,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isPrimary
                    ? const LinearGradient(
                        colors: [Color(0xFFF07020), Color(0xFFE67E22)],
                      )
                    : null,
                color: isPrimary ? null : AppColors.card,
                border: isPrimary
                    ? null
                    : Border.all(color: AppColors.border, width: 2.5),
                boxShadow: isPrimary
                    ? const [
                        BoxShadow(
                          color: Color(0x61E67E22),
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: isPrimary ? 32 : 26,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: labelColor,
            fontWeight: labelWeight,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Ghost card (stacked behind the top card) ────────────────────────────
// Web: rounded-[28px], border border-border, scale + translateY + blur

class DiscoverGhostCard extends StatelessWidget {
  const DiscoverGhostCard({
    required this.scale,
    required this.translateY,
    required this.opacity,
    super.key,
  });

  final double scale;
  final double translateY;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(scale.clamp(0.0, 1.0))
            ..translate(0.0, translateY),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Progress dots ───────────────────────────────────────────────────────
// Web: gap-1.5, max 9, current w-7 bg-primary, past w-2 bg-primary/30,
//      future w-2 bg-border

class DiscoverProgressDots extends StatelessWidget {
  const DiscoverProgressDots({
    required this.totalCount,
    required this.currentIndex,
    super.key,
  });

  final int totalCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final dotCount = totalCount.clamp(0, 9);
    if (dotCount <= 1) return const SizedBox(height: AppSpacing.xs);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(dotCount, (index) {
          final bool isCurrent = index == currentIndex;
          final bool isPast = index < currentIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: AppCurves.premiumEase,
            width: isCurrent ? 28 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderFull,
              color: isCurrent
                  ? AppColors.primary
                  : isPast
                      ? AppColors.primary.withValues(alpha: 0.30)
                      : AppColors.border,
            ),
          );
        }),
      ),
    );
  }
}

// ── Remaining count badge ───────────────────────────────────────────────
// Web: px-2.5 py-0.5 rounded-full text-xs font-semibold,
//      bg-primary-light text-primary-accessible, Users fill 11px

class DiscoverRemainingBadge extends StatelessWidget {
  const DiscoverRemainingBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsFill.users,
            size: 11,
            color: AppColors.primaryAccessible,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryAccessible,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
