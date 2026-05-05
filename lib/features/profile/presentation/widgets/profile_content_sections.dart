/// Content sections rendered below the hero on the My Profile screen.
///
/// Each section is an exact port of the matching block in tander-web's
/// `profile-page.tsx`:
///   • [ProfilePhotosSection] – Gallery header + photo grid (no card wrap)
///   • [ProfileInterestsSection] – tinted-icon heading + chips/empty
///   • [ProfileVitalFactsSection] – tinted-icon heading + rounded fact card
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_photo_grid.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_section_builders.dart';
import 'package:tander_flutter_v3/shared/widgets/photo_lightbox.dart';

const List<ProfileTone> _kInterestTones = [
  ProfileTone.primary,
  ProfileTone.secondary,
  ProfileTone.warm,
];

const List<ProfileTone> _kSnapshotTones = [
  ProfileTone.primary,
  ProfileTone.secondary,
  ProfileTone.warm,
];

// ── Photos section ────────────────────────────────────────────────────────

/// Gallery section: header row + photo grid (or empty prompt).
///
/// Web layout:
///   Header row (`flex items-center justify-between`):
///     • Title block — "Gallery" + uppercase caption
///     • Trailing — photo count pill (hidden on mobile) + "Manage" button
///   Body — [PhotoGrid] or [EmptyPrompt]; the header always renders.
class ProfilePhotosSection extends StatelessWidget {
  const ProfilePhotosSection({
    required this.gallery,
    required this.displayName,
    required this.onManage,
    required this.onAddPhoto,
    super.key,
  });

  final List<String> gallery;
  final String displayName;
  final VoidCallback onManage;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final isTabletWidth = MediaQuery.sizeOf(context).width >= 640;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gallery',
                      style: AppTypography.h2.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A WARMER FIRST IMPRESSION OF YOUR STORY',
                      style: AppTypography.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isTabletWidth) ...[
                _GalleryCountPill(
                  current: gallery.length,
                  total: maxPhotos,
                ),
                const SizedBox(width: 12),
              ],
              _ManageButton(
                label: gallery.isEmpty ? 'Manage' : 'Manage',
                onTap: onManage,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PhotoGrid(
          gallery: gallery,
          maxPhotoCount: maxPhotos,
          onPhotoTap: (index) => PhotoLightbox.show(
            context,
            photoUrls: gallery,
            initialIndex: index,
          ),
          onAddPhoto: onAddPhoto,
        ),
      ],
    );
  }
}

/// Tablet-only photo count pill — `0/6 PHOTOS`.
class _GalleryCountPill extends StatelessWidget {
  const _GalleryCountPill({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        '$current/$total PHOTOS',
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
          color: AppColors.primaryAccessible,
        ),
      ),
    );
  }
}

/// White-pill `Manage` button used on the Gallery header.
class _ManageButton extends StatelessWidget {
  const _ManageButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      shadowColor: const Color(0x14E67E22),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Interests section ─────────────────────────────────────────────────────

/// "Your Interests" block: tinted heart icon + heading + chips/empty.
class ProfileInterestsSection extends StatelessWidget {
  const ProfileInterestsSection({
    required this.interests,
    required this.hasInterests,
    required this.onChooseInterests,
    super.key,
  });

  final List<String> interests;
  final bool hasInterests;
  final VoidCallback onChooseInterests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          icon: Icons.favorite,
          tint: AppColors.secondary,
          title: 'Your Interests',
        ),
        const SizedBox(height: 24),
        if (hasInterests)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < interests.length; i++)
                InterestChip(
                  label: interests[i],
                  tone: _kInterestTones[i % _kInterestTones.length],
                ),
            ],
          )
        else
          EmptyPrompt(
            text: 'Adding interests helps us find better matches for you.',
            actionLabel: 'Choose Interests',
            onAction: onChooseInterests,
          ),
      ],
    );
  }
}

// ── Vital facts section ───────────────────────────────────────────────────

/// "Vital Facts" block: tinted users icon + heading + rounded fact card.
///
/// Card matches web's `rounded-[32px] border-2 border-border bg-white p-4`
/// with hairline dividers (`divide-border/40`) between rows.
class ProfileVitalFactsSection extends StatelessWidget {
  const ProfileVitalFactsSection({
    required this.snapshotItems,
    required this.onAddDetails,
    super.key,
  });

  final List<FactRowData> snapshotItems;
  final VoidCallback onAddDetails;

  @override
  Widget build(BuildContext context) {
    final hasFacts = snapshotItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          icon: Icons.people,
          tint: AppColors.primary,
          title: 'Vital Facts',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14E67E22),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: hasFacts
              ? Column(
                  children: [
                    for (int i = 0; i < snapshotItems.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border.withValues(alpha: 0.40),
                        ),
                      FactRow(
                        icon: snapshotItems[i].icon,
                        label: snapshotItems[i].label,
                        value: snapshotItems[i].value,
                        tone: _kSnapshotTones[i % _kSnapshotTones.length],
                      ),
                    ],
                  ],
                )
              : EmptyPrompt(
                  text: 'Complete your profile basics to get verified.',
                  actionLabel: 'Add Details',
                  onAction: onAddDetails,
                ),
        ),
      ],
    );
  }
}

// ── Shared section heading (tinted icon tile + title) ────────────────────

/// 40 × 40 tinted icon tile next to a bold display heading.
///
/// Used by both Interests and Vital Facts to match the web layout.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.tint,
    required this.title,
  });

  final IconData icon;
  final Color tint;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.h3.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
