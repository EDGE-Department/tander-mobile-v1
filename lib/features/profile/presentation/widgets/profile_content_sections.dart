/// Content section widgets for the profile screen (part 2).
///
/// Contains: [ProfilePhotosSection], [ProfileAboutSection],
/// [ProfileInterestsSection]. Separated from `profile_screen_sections.dart`
/// to keep each file under 400 lines.
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

// ── Constants ──────────────────────────────────────────────────────────

const double _tabletBreakpoint = 500;

const List<ProfileTone> _interestTones = [
  ProfileTone.primary,
  ProfileTone.secondary,
  ProfileTone.warm,
];

const List<ProfileTone> _snapshotTones = [
  ProfileTone.primary,
  ProfileTone.secondary,
  ProfileTone.warm,
];

const List<ProfileTone> _detailTones = [
  ProfileTone.warm,
  ProfileTone.primary,
  ProfileTone.secondary,
];

// ── Photos section ─────────────────────────────────────────────────────

class ProfilePhotosSection extends StatelessWidget {
  const ProfilePhotosSection({
    required this.gallery,
    required this.displayName,
    super.key,
  });

  final List<String> gallery;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final String titleSuffix =
        gallery.isNotEmpty ? ' (${gallery.length}/$maxPhotos)' : '';
    return SectionCard(
      title: 'Photos$titleSuffix',
      actionLabel: gallery.isNotEmpty ? 'Manage' : 'Add photos',
      onAction: () {
        // TODO(#124): Open photos sheet
      },
      child: PhotoGrid(
        gallery: gallery,
        maxPhotoCount: maxPhotos,
        onPhotoTap: (index) => PhotoLightbox.show(
          context,
          photoUrls: gallery,
          initialIndex: index,
        ),
        onAddPhoto: () {
          // TODO(#124): Open photos sheet
        },
      ),
    );
  }
}

// ── About section (responsive: 2-col on tablet) ───────────────────────

class ProfileAboutSection extends StatelessWidget {
  const ProfileAboutSection({
    required this.bio,
    required this.hasBio,
    required this.snapshotItems,
    super.key,
  });

  final String bio;
  final bool hasBio;
  final List<FactRowData> snapshotItems;

  @override
  Widget build(BuildContext context) {
    final isTablet =
        MediaQuery.of(context).size.width >= _tabletBreakpoint;

    final aboutCard = _buildAboutCard();
    final snapshotCard = _buildSnapshotCard();

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: aboutCard),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: snapshotCard),
        ],
      );
    }

    return Column(
      children: [
        aboutCard,
        const SizedBox(height: AppSpacing.sm),
        snapshotCard,
      ],
    );
  }

  Widget _buildAboutCard() {
    return SectionCard(
      title: 'About me',
      actionLabel: hasBio ? 'Edit' : 'Add intro',
      onAction: () {
        // TODO(#124): Open edit sheet
      },
      child: hasBio
          ? Container(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Text(
                bio,
                style: AppTypography.body.copyWith(height: 1.9),
              ),
            )
          : EmptyPrompt(
              text:
                  'Share a few lines about your story, daily routine, or what matters to you.',
              actionLabel: 'Write your intro',
              onAction: () {
                // TODO(#124): Open edit sheet
              },
            ),
    );
  }

  Widget _buildSnapshotCard() {
    return SectionCard(
      title: 'Profile snapshot',
      actionLabel: 'Edit',
      onAction: () {
        // TODO(#124): Open edit sheet
      },
      child: snapshotItems.isNotEmpty
          ? Column(
              children: [
                for (int index = 0;
                    index < snapshotItems.length;
                    index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.border),
                  FactRow(
                    icon: snapshotItems[index].icon,
                    label: snapshotItems[index].label,
                    value: snapshotItems[index].value,
                    tone: _snapshotTones[index % _snapshotTones.length],
                  ),
                ],
              ],
            )
          : EmptyPrompt(
              text:
                  'Add basics like your location, age, and what you are looking for.',
              actionLabel: 'Complete basics',
              onAction: () {
                // TODO(#124): Open edit sheet
              },
            ),
    );
  }
}

// ── Interests section (responsive: 2-col on tablet) ───────────────────

class ProfileInterestsSection extends StatelessWidget {
  const ProfileInterestsSection({
    required this.interests,
    required this.hasInterests,
    required this.detailItems,
    super.key,
  });

  final List<String> interests;
  final bool hasInterests;
  final List<FactRowData> detailItems;

  @override
  Widget build(BuildContext context) {
    final isTablet =
        MediaQuery.of(context).size.width >= _tabletBreakpoint;

    final interestsCard = _buildInterestsCard();
    final detailsCard = _buildDetailsCard();

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: interestsCard),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: detailsCard),
        ],
      );
    }

    return Column(
      children: [
        interestsCard,
        const SizedBox(height: AppSpacing.sm),
        detailsCard,
      ],
    );
  }

  Widget _buildInterestsCard() {
    return SectionCard(
      title: 'Interests',
      actionLabel: hasInterests ? 'Edit' : 'Add interests',
      onAction: () {
        // TODO(#124): Open edit sheet
      },
      child: hasInterests
          ? Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (int index = 0; index < interests.length; index++)
                  InterestChip(
                    label: interests[index],
                    tone: _interestTones[index % _interestTones.length],
                  ),
              ],
            )
          : EmptyPrompt(
              text:
                  'Add a few hobbies so people have natural conversation starters.',
              actionLabel: 'Choose interests',
              onAction: () {
                // TODO(#124): Open edit sheet
              },
            ),
    );
  }

  Widget _buildDetailsCard() {
    return SectionCard(
      title: 'More details',
      actionLabel: 'Edit',
      onAction: () {
        // TODO(#124): Open edit sheet
      },
      child: detailItems.isNotEmpty
          ? Column(
              children: [
                for (int index = 0;
                    index < detailItems.length;
                    index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.border),
                  FactRow(
                    icon: detailItems[index].icon,
                    label: detailItems[index].label,
                    value: detailItems[index].value,
                    tone: _detailTones[index % _detailTones.length],
                  ),
                ],
              ],
            )
          : EmptyPrompt(
              text:
                  'Add details like hobbies, education, languages, or family information.',
              actionLabel: 'Add details',
              onAction: () {
                // TODO(#124): Open edit sheet
              },
            ),
    );
  }
}
