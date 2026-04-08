/// Hero banner for the profile screen with cover image, avatar, identity,
/// completion badge, and meta pills.
///
/// Phone layout: centered avatar + name stack, 96 px avatar, 140 px cover.
/// Tablet layout (>= 600 px): side-by-side avatar + name, 112 px avatar,
/// 180 px cover. A [CompletionRingPainter] draws the progress arc.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_hero_parts.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_badge.dart';

const double _mobileAvatarSize = 96;
const double _tabletAvatarSize = 112;
const double _coverHeightMobile = 140;
const double _coverHeightTablet = 180;
const double _changePhotoSize = 32;
const double _tabletChangePhotoSize = 36;

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
    final bool isTablet =
        MediaQuery.of(context).size.width >= 1024;
    final double avatarSize =
        isTablet ? _tabletAvatarSize : _mobileAvatarSize;
    final double coverHeight =
        isTablet ? _coverHeightTablet : _coverHeightMobile;
    final double horizontalPadding =
        isTablet ? AppSpacing.lg : AppSpacing.sm;

    return Column(
      children: [
        _buildCoverBanner(coverHeight, isTablet, horizontalPadding),
        _buildAvatarAndIdentity(
          avatarSize,
          isTablet,
          horizontalPadding,
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildBadgesAndMeta(isTablet, horizontalPadding),
        SizedBox(height: isTablet ? AppSpacing.sm : AppSpacing.xs),
      ],
    );
  }

  // ── Cover banner ──────────────────────────────────────────────────

  Widget _buildCoverBanner(
    double coverHeight,
    bool isTablet,
    double horizontalPadding,
  ) {
    final coverUrl = gallery.length > 1 ? gallery[1] : gallery.firstOrNull;
    final photoButtonSize =
        isTablet ? _tabletChangePhotoSize : _changePhotoSize;

    return SizedBox(
      height: coverHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            Image.network(
                  coverUrl,
              fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => heroDefaultGradient(),
            )
          else
            heroDefaultGradient(),
          heroBottomGradientOverlay(),
          Positioned(
            top: AppSpacing.sm,
            left: horizontalPadding,
            right: horizontalPadding,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeroCompletionPill(
                    completionPercent: completionPercent,
                    isProfileComplete: isProfileComplete,
                  ),
                  GestureDetector(
                    onTap: onChangePhoto,
                    child: Container(
                      width: photoButtonSize,
                      height: photoButtonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar + Identity ─────────────────────────────────────────────

  Widget _buildAvatarAndIdentity(
    double avatarSize,
    bool isTablet,
    double horizontalPadding,
  ) {
    final avatarWidget = HeroAvatar(
      gallery: gallery,
      displayName: displayName,
      isOnline: isOnline,
      completionPercent: completionPercent,
      avatarSize: avatarSize,
      borderWidth: isTablet ? 4.0 : 3.5,
      onChangePhoto: onChangePhoto,
    );

    final identityWidget = HeroIdentityText(
      displayName: displayName,
      username: username,
      isOnline: isOnline,
      isTablet: isTablet,
    );

    return Transform.translate(
      offset: Offset(0, -avatarSize / 2),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  avatarWidget,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: identityWidget,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  avatarWidget,
                  const SizedBox(height: AppSpacing.xs),
                  identityWidget,
                ],
              ),
      ),
    );
  }

  // ── Badges and meta ───────────────────────────────────────────────

  Widget _buildBadgesAndMeta(bool isTablet, double horizontalPadding) {
    final alignment =
        isTablet ? WrapAlignment.start : WrapAlignment.center;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Wrap(
        alignment: alignment,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xxs,
        children: [
          TanderBadge(label: tierLabel),
          if (isVerified)
            const TanderBadge(
              label: 'Verified',
              variant: TanderBadgeVariant.info,
              icon: Icons.verified_user,
            ),
          if (displayLocation.isNotEmpty)
            HeroMetaPill(
              icon: Icons.location_on,
              iconColor: AppColors.primary,
              label: displayLocation,
            ),
          if (age != null)
            HeroMetaPill(
              icon: Icons.calendar_today,
              iconColor: AppColors.secondary,
              label: '$age years old',
            ),
          if (gender != null)
            HeroMetaPill(
              icon: Icons.people,
              iconColor: AppColors.primary,
              label: gender!,
            ),
          if (lookingFor != null)
            HeroMetaPill(
              icon: Icons.favorite,
              iconColor: AppColors.danger,
              label: lookingFor!,
            ),
        ],
      ),
    );
  }
}
