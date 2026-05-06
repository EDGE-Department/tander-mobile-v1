/// Profile hero section — always centered, scales gracefully on all screens.
///
/// No cover banner. Flat layout with ambient glows, large rounded avatar
/// with gradient ring, social stats row, bio, and meta pills.
/// Always uses centered column layout - works on phones, tablets, any orientation.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/utils/photo_url.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_badge.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    required this.gallery,
    required this.displayName,
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
    this.interestsCount = 0,
    this.bio = '',
    super.key,
  });

  final List<String> gallery;
  final String displayName;
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
  final int interestsCount;
  final String bio;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Scale avatar: 128px on small screens, up to 160px on larger screens
    final avatarSize = screenWidth < 400 ? 120.0 : (screenWidth < 600 ? 128.0 : 160.0);

    // Constrain content width on very wide screens for readability
    final maxContentWidth = 500.0;

    return Stack(
      children: [
        // Ambient glows - positioned relative to center
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: maxContentWidth + 100,
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content - always centered
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  _buildAvatar(avatarSize),
                  const SizedBox(height: 28),
                  _buildIdentity(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(double size) {
    final hasPhoto = gallery.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
                Color(0xFFFB923C),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4DE67E22),
                blurRadius: 64,
                offset: Offset(0, 32),
                spreadRadius: -12,
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.26),
              border: Border.all(color: Colors.white, width: 4),
              color: AppColors.subtle,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    resolvePhotoUrl(gallery[0]) ?? gallery[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
        ),

        if (isOnline)
          Positioned(
            bottom: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFECFDF5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.person, size: 56, color: AppColors.primary),
      ),
    );
  }

  Widget _buildIdentity() {
    return Column(
      children: [
        // Name + badges
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: AppTypography.h1.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (isVerified)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 20,
                  color: AppColors.secondary,
                ),
              ),
            TanderBadge(label: tierLabel),
          ],
        ),
        const SizedBox(height: 20),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatTile(
              value: '${gallery.length}',
              label: 'PHOTOS',
              valueColor: AppColors.textStrong,
            ),
            const SizedBox(width: 36),
            _StatTile(
              value: '$interestsCount',
              label: 'INTERESTS',
              valueColor: AppColors.secondary,
            ),
            const SizedBox(width: 36),
            _StatTile(
              value: '$completionPercent',
              label: 'STRENGTH',
              valueColor: AppColors.primaryAccessible,
              suffix: '%',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Bio
        if (bio.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textBody,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Meta pills
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            if (displayLocation.isNotEmpty)
              _MetaPill(
                icon: Icons.location_on,
                iconColor: AppColors.primary,
                label: displayLocation,
              ),
            if (age != null)
              _MetaPill(
                icon: Icons.calendar_today,
                iconColor: AppColors.secondary,
                label: '$age Yrs',
              ),
            if (gender != null)
              _MetaPill(
                icon: Icons.people,
                iconColor: AppColors.primary,
                label: gender!,
              ),
            if (lookingFor != null)
              _MetaPill(
                icon: Icons.favorite,
                iconColor: AppColors.danger,
                label: lookingFor!,
              ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
    this.suffix,
  });

  final String value;
  final String label;
  final Color valueColor;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: valueColor,
                height: 1.0,
              ),
            ),
            if (suffix != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  suffix!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: valueColor.withValues(alpha: 0.60),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
