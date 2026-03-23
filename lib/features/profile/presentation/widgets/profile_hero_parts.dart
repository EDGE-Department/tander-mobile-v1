/// Sub-widgets for the profile hero: avatar, identity text, meta pills,
/// completion pill, and shared decorative builders.
///
/// Extracted from `profile_hero.dart` to keep each file under 400 lines.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/completion_ring_painter.dart';

const double _ringStrokeWidth = 3;
const double _changePhotoSize = 32;

// ── Shared gradient builders ───────────────────────────────────────────

/// Default cover gradient for profiles without a cover photo.
Widget heroDefaultGradient() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-0.7, -1),
        end: Alignment(0.7, 1),
        colors: [Color(0xFFF5B577), Color(0xFFE67E22), Color(0xFF0F9D94)],
      ),
    ),
  );
}

/// Dark gradient overlay at the bottom of the cover banner.
Widget heroBottomGradientOverlay() {
  return Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.05),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.25),
          ],
        ),
      ),
    ),
  );
}

// ── Completion pill ────────────────────────────────────────────────────

/// Pill badge showing profile completion status on the cover banner.
class HeroCompletionPill extends StatelessWidget {
  const HeroCompletionPill({
    required this.completionPercent,
    required this.isProfileComplete,
    super.key,
  });

  final int completionPercent;
  final bool isProfileComplete;

  @override
  Widget build(BuildContext context) {
    if (isProfileComplete) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.8),
          borderRadius: AppRadius.borderFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 12,
              color: AppColors.textInverse,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'Complete',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textInverse,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: AppRadius.borderFull,
      ),
      child: Text(
        '$completionPercent% complete',
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textInverse,
        ),
      ),
    );
  }
}

// ── Avatar with completion ring ────────────────────────────────────────

/// Circular avatar with progress ring, online dot, and camera button.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    required this.gallery,
    required this.displayName,
    required this.isOnline,
    required this.completionPercent,
    required this.avatarSize,
    required this.borderWidth,
    required this.onChangePhoto,
    super.key,
  });

  final List<String> gallery;
  final String displayName;
  final bool isOnline;
  final int completionPercent;
  final double avatarSize;
  final double borderWidth;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final double ringSize = avatarSize + _ringStrokeWidth * 2 + 4;
    final bool hasImage = gallery.isNotEmpty && gallery.first.isNotEmpty;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (completionPercent < 100)
            CustomPaint(
              size: Size(ringSize, ringSize),
              painter: CompletionRingPainter(
                progress: completionPercent / 100,
                strokeWidth: _ringStrokeWidth,
              ),
            ),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: gallery.first,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          _InitialsFallback(displayName: displayName),
                      errorWidget: (_, _, _) =>
                          _InitialsFallback(displayName: displayName),
                    )
                  : _InitialsFallback(displayName: displayName),
            ),
          ),
          if (isOnline)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2.5),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onChangePhoto,
              child: Container(
                width: _changePhotoSize,
                height: _changePhotoSize,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts[0][0].toUpperCase()
            : '${parts.first[0]}${parts.last[0]}'.toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, Color(0xFFFDE8CC)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.h2.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Identity text ──────────────────────────────────────────────────────

/// Display name and username with online status indicator.
class HeroIdentityText extends StatelessWidget {
  const HeroIdentityText({
    required this.displayName,
    required this.username,
    required this.isOnline,
    required this.isTablet,
    super.key,
  });

  final String displayName;
  final String username;
  final bool isOnline;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final alignment =
        isTablet ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = isTablet ? TextAlign.start : TextAlign.center;
    final rowAlignment =
        isTablet ? MainAxisAlignment.start : MainAxisAlignment.center;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          displayName,
          style: isTablet
              ? AppTypography.h2.copyWith(fontSize: 26)
              : AppTypography.h3,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: rowAlignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '@$username',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: AppTypography.caption.copyWith(
                color:
                    isOnline ? AppColors.success : AppColors.textDisabled,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Meta pill ──────────────────────────────────────────────────────────

/// Small icon + label pill for location, age, gender, etc.
class HeroMetaPill extends StatelessWidget {
  const HeroMetaPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
