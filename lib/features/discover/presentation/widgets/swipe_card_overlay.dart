/// Profile info overlay and stamp widgets for the swipe card.
///
/// Extracted from swipe_card.dart to keep files under 400 lines.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _likeStampBorder = Color(0xFF2E8B57);
const Color _nopeStampBorder = Color(0xFFC0392B);
const int _maxInterestChips = 4;
const int _maxBioLines = 2;

// ── Stamps ──────────────────────────────────────────────────────────

class SwipeLikeStamp extends StatelessWidget {
  const SwipeLikeStamp({required this.opacity, super.key});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned(
      top: 56, left: 20,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: -20 * math.pi / 180,
          child: _stampContainer(
            borderColor: _likeStampBorder,
            icon: PhosphorIconsFill.heart,
            iconColor: AppColors.success,
            label: 'LIKE',
            labelColor: AppColors.success,
          ),
        ),
      ),
    );
  }
}

class SwipeNopeStamp extends StatelessWidget {
  const SwipeNopeStamp({required this.opacity, super.key});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned(
      top: 56, right: 20,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: 20 * math.pi / 180,
          child: _stampContainer(
            borderColor: _nopeStampBorder,
            icon: PhosphorIconsBold.x,
            iconColor: AppColors.danger,
            label: 'NOPE',
            labelColor: AppColors.danger,
          ),
        ),
      ),
    );
  }
}

Widget _stampContainer({
  required Color borderColor,
  required IconData icon,
  required Color iconColor,
  required String label,
  required Color labelColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: borderColor, width: 3),
      borderRadius: AppRadius.borderLg,
      color: borderColor.withValues(alpha: 0.14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.label.copyWith(
          color: labelColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3.2,
        )),
      ],
    ),
  );
}

// ── Bottom gradient ─────────────────────────────────────────────────

class SwipeBottomGradient extends StatelessWidget {
  const SwipeBottomGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: const [0.0, 0.35, 0.60, 1.0],
            colors: [
              const Color(0xF2080301), const Color(0xB3080301),
              const Color(0x47080301), Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Photo indicators ────────────────────────────────────────────────

class SwipePhotoIndicators extends StatelessWidget {
  const SwipePhotoIndicators({required this.photoCount, required this.activeIndex, super.key});
  final int photoCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    if (photoCount <= 1) return const SizedBox.shrink();
    return Positioned(
      top: AppSpacing.md, left: AppSpacing.md, right: AppSpacing.md,
      child: Row(
        children: List.generate(photoCount, (index) {
          final bool isActive = index == activeIndex;
          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: index < photoCount - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.36),
                borderRadius: AppRadius.borderFull,
                boxShadow: isActive
                    ? const [BoxShadow(color: Color(0x51000000), blurRadius: 4, offset: Offset(0, 1))]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Profile info overlay ────────────────────────────────────────────

class SwipeProfileOverlay extends StatelessWidget {
  const SwipeProfileOverlay({required this.candidate, required this.onViewProfile, super.key});
  final DiscoveryCandidate candidate;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNameAge(),
            if (candidate.city != null || candidate.country != null) ...[
              const SizedBox(height: 4), _buildLocation(),
            ],
            if (candidate.bio != null && candidate.bio!.isNotEmpty) ...[
              const SizedBox(height: 8), _buildBio(),
            ],
            if (candidate.interests.isNotEmpty) ...[
              const SizedBox(height: 12), _buildInterestChips(),
            ],
            const SizedBox(height: 16),
            _buildViewProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameAge() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(candidate.firstName, style: AppTypography.displayLg.copyWith(
            color: AppColors.textInverse, fontWeight: FontWeight.w800, fontSize: 33, height: 1.0,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (candidate.age != null) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('${candidate.age}', style: AppTypography.h1.copyWith(
              color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w300, fontSize: 25, height: 1.0,
            )),
          ),
        ],
        if (candidate.isOnline) ...[const SizedBox(width: 10), _onlineBadge()],
      ],
    );
  }

  Widget _onlineBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xB32E8B57), borderRadius: AppRadius.borderFull,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.textInverse, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('Online now', style: AppTypography.caption.copyWith(color: AppColors.textInverse, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Widget _buildLocation() {
    final parts = [candidate.city, candidate.country].where((p) => p != null && p.isNotEmpty).join(', ');
    return Row(children: [
      const Icon(PhosphorIconsFill.mapPin, size: 13, color: AppColors.textInverse),
      const SizedBox(width: 6),
      Flexible(child: Text(parts, style: AppTypography.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.72)), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }

  Widget _buildBio() {
    return Text(candidate.bio!, style: AppTypography.bodySm.copyWith(
      color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.4,
    ), maxLines: _maxBioLines, overflow: TextOverflow.ellipsis);
  }

  Widget _buildInterestChips() {
    final visible = candidate.interests.take(_maxInterestChips).toList();
    final overflowCount = candidate.interests.length - _maxInterestChips;
    return Wrap(spacing: 6, runSpacing: 6, children: [
      ...visible.map((interest) => _chip(interest, Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.26), AppColors.textInverse)),
      if (overflowCount > 0) _chip('+$overflowCount', Colors.white.withValues(alpha: 0.10), Colors.transparent, Colors.white.withValues(alpha: 0.65)),
    ]);
  }

  Widget _chip(String text, Color bgColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: AppRadius.borderFull,
        border: borderColor != Colors.transparent ? Border.all(color: borderColor) : null,
      ),
      child: Text(text, style: AppTypography.caption.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildViewProfileButton() {
    return GestureDetector(
      onTap: onViewProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16), borderRadius: AppRadius.borderFull,
          border: Border.all(color: Colors.white.withValues(alpha: 0.32), width: 1.5),
        ),
        child: Text('View full profile \u2192', style: AppTypography.label.copyWith(
          color: AppColors.textInverse, fontWeight: FontWeight.w700, fontSize: 14,
        )),
      ),
    );
  }
}
