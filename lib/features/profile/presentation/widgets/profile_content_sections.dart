/// Content section widgets for the profile screen (part 2).
///
/// Contains: [ProfilePhotosSection], [ProfileAboutSection],
/// [ProfileInterestsSection]. Separated from `profile_screen_sections.dart`
/// to keep each file under 400 lines.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_photos_screen.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_photo_grid.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_section_builders.dart';
import 'package:tander_flutter_v3/shared/widgets/photo_lightbox.dart';

// ── Constants ──────────────────────────────────────────────────────────

const double _tabletBreakpoint = 500;

void _openEditSheet(BuildContext context) {
  _showFullScreenSheet(context, const ProfileEditScreen());
}

void _openPhotosSheet(BuildContext context) {
  _showFullScreenSheet(context, const ProfilePhotosScreen());
}

void _showFullScreenSheet(BuildContext context, Widget child) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.none,
        child: FractionallySizedBox(heightFactor: 0.92, child: child),
      ),
    ),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

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
      onAction: () => _openPhotosSheet(context),
      child: PhotoGrid(
        gallery: gallery,
        maxPhotoCount: maxPhotos,
        onPhotoTap: (index) => PhotoLightbox.show(
          context,
          photoUrls: gallery,
          initialIndex: index,
        ),
        onAddPhoto: () => _openPhotosSheet(context),
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

    final aboutCard = _buildAboutCard(context);
    final snapshotCard = _buildSnapshotCard(context);

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

  Widget _buildAboutCard(BuildContext context) {
    return SectionCard(
      title: 'About me',
      actionLabel: hasBio ? 'Edit' : 'Add intro',
      onAction: () => _openEditSheet(context),
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
              onAction: () => _openEditSheet(context),
            ),
    );
  }

  Widget _buildSnapshotCard(BuildContext context) {
    return SectionCard(
      title: 'Profile snapshot',
      actionLabel: 'Edit',
      onAction: () => _openEditSheet(context),
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
              onAction: () => _openEditSheet(context),
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

    final interestsCard = _buildInterestsCard(context);
    final detailsCard = _buildDetailsCard(context);

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

  Widget _buildInterestsCard(BuildContext context) {
    return SectionCard(
      title: 'Interests',
      actionLabel: hasInterests ? 'Edit' : 'Add interests',
      onAction: () => _openEditSheet(context),
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
              onAction: () => _openEditSheet(context),
            ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return SectionCard(
      title: 'More details',
      actionLabel: 'Edit',
      onAction: () => _openEditSheet(context),
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
              onAction: () => _openEditSheet(context),
            ),
    );
  }
}

// ── Shared sheet scaffold ─────────────────────────────────────────────────

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.onClose, required this.child});
  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textStrong))),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18)),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),
        Expanded(child: child),
      ],
    );
  }
}

class _EditSheetPlaceholder extends StatelessWidget {
  const _EditSheetPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Edit profile form — coming soon', style: TextStyle(color: AppColors.textMuted)));
  }
}

class _PhotosSheetPlaceholder extends StatelessWidget {
  const _PhotosSheetPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Photo management — coming soon', style: TextStyle(color: AppColors.textMuted)));
  }
}
