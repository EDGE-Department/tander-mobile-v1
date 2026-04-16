/// Profile hero section — 1:1 replica of web's ProfileHero.
///
/// No cover banner. Flat layout with ambient glows, large rounded avatar
/// with gradient ring, social stats row, bio, and meta pills.
/// Phone: centered column. Tablet (>=640): side-by-side row.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_badge.dart';

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
    this.interestsCount = 0,
    this.bio = '',
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
  final int interestsCount;
  final String bio;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 640;
    // Web: h-32 w-32 (128px) mobile, sm:h-44 sm:w-44 (176px) tablet
    final avatarSize = isTablet ? 176.0 : 128.0;

    return Stack(
      children: [
        // Ambient glows behind identity
        Positioned(
          top: 0,
          left: screenWidth * 0.15,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          top: 60,
          right: screenWidth * 0.15,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.08),
            ),
          ),
        ),

        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            isTablet ? 64 : 40,
            16,
            isTablet ? 48 : 32,
          ),
          child: isTablet
              ? _buildTabletLayout(avatarSize)
              : _buildMobileLayout(avatarSize),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double avatarSize) {
    return Column(
      children: [
        _buildAvatar(avatarSize),
        const SizedBox(height: 32),
        _buildIdentity(centered: true),
      ],
    );
  }

  Widget _buildTabletLayout(double avatarSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(avatarSize),
        const SizedBox(width: 48),
        Expanded(child: _buildIdentity(centered: false)),
      ],
    );
  }

  // ── Avatar with gradient ring + online badge ────────────────────────

  Widget _buildAvatar(double size) {
    final hasPhoto = gallery.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Web: rounded-[40px] p-1.5 gradient ring, shadow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
                Color(0xFFFB923C), // orange-400
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
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white, width: 5),
              color: AppColors.subtle,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    gallery[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, _, _) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
        ),

        // Web: online badge — -bottom-2 -right-2, "ACTIVE" text
        if (isOnline)
          Positioned(
            bottom: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFECFDF5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
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

  // ── Identity: name, badges, stats, username, bio, meta ──────────────

  Widget _buildIdentity({required bool centered}) {
    final alignment = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.left;
    final wrapAlignment = centered ? WrapAlignment.center : WrapAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Name + verification + tier badge
        Wrap(
          alignment: wrapAlignment,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            // Web: font-display text-3xl sm:text-4xl font-black
            Text(
              displayName,
              textAlign: textAlign,
              style: AppTypography.h1.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (isVerified)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 22,
                  color: AppColors.secondary,
                ),
              ),
            TanderBadge(label: tierLabel),
          ],
        ),
        const SizedBox(height: 24),

        // Social stats row — Web: gap-10 sm:gap-14
        Row(
          mainAxisAlignment:
              centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            _StatTile(
              value: '${gallery.length}',
              label: 'PHOTOS',
              valueColor: AppColors.textStrong,
            ),
            SizedBox(width: centered ? 40 : 56),
            _StatTile(
              value: '$interestsCount',
              label: 'INTERESTS',
              valueColor: AppColors.secondary,
            ),
            SizedBox(width: centered ? 40 : 56),
            _StatTile(
              value: '$completionPercent',
              label: 'STRENGTH',
              valueColor: AppColors.primaryAccessible,
              suffix: '%',
            ),
          ],
        ),
        const SizedBox(height: 32),

        // @username + bio
        Text(
          '@$username',
          textAlign: textAlign,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            bio,
            textAlign: textAlign,
            maxLines: centered ? 3 : null,
            overflow: centered ? TextOverflow.ellipsis : null,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textBody,
              height: 1.6,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Meta pills — Web: text-[13px] font-black uppercase tracking-wider
        Wrap(
          alignment: wrapAlignment,
          spacing: 20,
          runSpacing: 10,
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

// ── Stat tile ─────────────────────────────────────────────────────────

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
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: valueColor,
                height: 1.0,
              ),
            ),
            if (suffix != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  suffix!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: valueColor.withValues(alpha: 0.60),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.2,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Meta pill ─────────────────────────────────────────────────────────

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
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
