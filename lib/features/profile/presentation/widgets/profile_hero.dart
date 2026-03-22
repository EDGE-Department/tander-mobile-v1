/// Hero banner for the profile screen with cover image, avatar, identity,
/// completion badge, and meta pills.
///
/// The avatar scales from 96 px on phones to 112 px on tablets via
/// [LayoutBuilder]. A [CompletionRingPainter] draws the progress arc.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/completion_ring_painter.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_badge.dart';

const double _mobileAvatarSize = 96;
const double _tabletAvatarSize = 112;
const double _tabletBreakpoint = 600;
const double _coverHeightMobile = 140;
const double _coverHeightTablet = 180;
const double _changePhotoSize = 32;
const double _ringStrokeWidth = 3;

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    required this.gallery,
    required this.displayName,
    required this.username,
    required this.isOnline,
    required this.completionPercent,
    required this.isProfileComplete,
    required this.tierLabel,
    required this.isVerified,
    required this.displayLocation,
    required this.age,
    required this.gender,
    required this.lookingFor,
    required this.onChangePhoto,
    super.key,
  });

  final List<String> gallery;
  final String displayName;
  final String username;
  final bool isOnline;
  final int completionPercent;
  final bool isProfileComplete;
  final String tierLabel;
  final bool isVerified;
  final String displayLocation;
  final int? age;
  final String? gender;
  final String? lookingFor;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isTablet = constraints.maxWidth >= _tabletBreakpoint;
      final double avatarSize = isTablet ? _tabletAvatarSize : _mobileAvatarSize;
      final double coverHeight = isTablet ? _coverHeightTablet : _coverHeightMobile;

      return Column(
        children: [
          _buildCoverBanner(coverHeight),
          Transform.translate(
            offset: Offset(0, -avatarSize / 2),
            child: Column(
              children: [
                _buildAvatar(avatarSize),
                const SizedBox(height: AppSpacing.xs),
                _buildIdentity(),
                const SizedBox(height: AppSpacing.xs),
                _buildBadgesAndMeta(),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ── Cover banner ─────────────────────────────────────────────────────

  Widget _buildCoverBanner(double coverHeight) {
    final coverUrl = gallery.length > 1 ? gallery[1] : gallery.firstOrNull;
    return SizedBox(
      height: coverHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => _defaultGradient(),
              errorWidget: (_, _, _) => _defaultGradient(),
            )
          else
            _defaultGradient(),
          _bottomGradientOverlay(),
          _topControls(),
        ],
      ),
    );
  }

  Widget _defaultGradient() {
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

  Widget _bottomGradientOverlay() {
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

  Widget _topControls() {
    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCompletionPill(),
            _buildChangePhotoButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionPill() {
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
            const Icon(PhosphorIconsFill.checkCircle, size: 12, color: AppColors.textInverse),
            const SizedBox(width: AppSpacing.xxs),
            Text('Complete', style: AppTypography.caption.copyWith(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textInverse)),
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
      child: Text('$completionPercent% complete', style: AppTypography.caption.copyWith(
        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textInverse)),
    );
  }

  Widget _buildChangePhotoButton() {
    return GestureDetector(
      onTap: onChangePhoto,
      child: Container(
        width: _changePhotoSize,
        height: _changePhotoSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: const Icon(PhosphorIconsBold.camera, size: 14, color: AppColors.textInverse),
      ),
    );
  }

  // ── Avatar with ring ─────────────────────────────────────────────────

  Widget _buildAvatar(double avatarSize) {
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
              painter: CompletionRingPainter(progress: completionPercent / 100, strokeWidth: _ringStrokeWidth),
            ),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: 3.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ClipOval(
              child: hasImage
                  ? CachedNetworkImage(imageUrl: gallery.first, fit: BoxFit.cover,
                      placeholder: (_, _) => _initialsFallback(), errorWidget: (_, _, _) => _initialsFallback())
                  : _initialsFallback(),
            ),
          ),
          if (isOnline)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(width: 14, height: 14,
                decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: AppColors.card, width: 2.5))),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onChangePhoto,
              child: Container(
                width: _changePhotoSize, height: _changePhotoSize,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.card, width: 2)),
                alignment: Alignment.center,
                child: const Icon(PhosphorIconsBold.camera, size: 14, color: AppColors.textInverse),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsFallback() {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty ? '?' : parts.length == 1
        ? parts[0][0].toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryLight, Color(0xFFFDE8CC)])),
      alignment: Alignment.center,
      child: Text(initials, style: AppTypography.h2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
    );
  }

  // ── Identity ─────────────────────────────────────────────────────────

  Widget _buildIdentity() {
    return Column(
      children: [
        Text(displayName, style: AppTypography.h2, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('@$username', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            const SizedBox(width: AppSpacing.xs),
            Text(isOnline ? 'Online' : 'Offline', style: AppTypography.caption.copyWith(
              color: isOnline ? AppColors.success : AppColors.textDisabled, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // ── Badges and meta ──────────────────────────────────────────────────

  Widget _buildBadgesAndMeta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xxs,
        children: [
          TanderBadge(label: tierLabel),
          if (isVerified) const TanderBadge(label: 'Verified', variant: TanderBadgeVariant.info, icon: PhosphorIconsFill.shieldCheck),
          if (displayLocation.isNotEmpty) _metaPill(PhosphorIconsFill.mapPin, AppColors.primary, displayLocation),
          if (age != null) _metaPill(PhosphorIconsFill.calendar, AppColors.secondary, '$age years old'),
          if (gender != null) _metaPill(PhosphorIconsFill.users, AppColors.primary, gender!),
          if (lookingFor != null) _metaPill(PhosphorIconsFill.heart, AppColors.danger, lookingFor!),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, Color iconColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 3),
        Flexible(child: Text(label, style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w500, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
