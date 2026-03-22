/// Section widgets for the profile screen loaded state.
///
/// Extracted from `profile_screen.dart` to keep each file under 400 lines.
/// Contains: [ProfileActionRow], [ProfileMetricRow], [ProfileCompletionSection],
/// [ProfilePhotosSection], [ProfileAboutSection], [ProfileInterestsSection].
library;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_photo_grid.dart';
import 'package:tander_flutter_v3/shared/widgets/photo_lightbox.dart';

// ── Tone cycles ──────────────────────────────────────────────────────────

const List<ProfileTone> _interestTones = [ProfileTone.primary, ProfileTone.secondary, ProfileTone.warm];
const List<ProfileTone> _factTones = [ProfileTone.primary, ProfileTone.secondary, ProfileTone.warm];

// ── Action row ───────────────────────────────────────────────────────────

class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    required this.onEdit,
    required this.onPhotos,
    required this.onSettings,
    required this.onHelp,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PrimaryAction(label: 'Edit profile', onTap: onEdit),
          const SizedBox(width: AppSpacing.xs),
          _SecondaryAction(icon: PhosphorIconsFill.images, label: 'Photos', onTap: onPhotos),
          const SizedBox(width: AppSpacing.xs),
          _SecondaryAction(icon: PhosphorIconsFill.gear, label: 'Settings', onTap: onSettings),
          const SizedBox(width: AppSpacing.xs),
          _SecondaryAction(icon: PhosphorIconsFill.question, label: 'Help', onTap: onHelp),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.borderMd, boxShadow: AppShadows.warmSm),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(PhosphorIconsBold.pencilSimple, size: 16, color: AppColors.textInverse),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.label.copyWith(color: AppColors.textInverse)),
        ]),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.borderMd, border: Border.all(color: AppColors.border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.textBody),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: AppTypography.label),
        ]),
      ),
    );
  }
}

// ── Metric row ───────────────────────────────────────────────────────────

class ProfileMetricRow extends StatelessWidget {
  const ProfileMetricRow({
    required this.completionPercent,
    required this.photoCount,
    required this.interestCount,
    super.key,
  });

  final int completionPercent;
  final int photoCount;
  final int interestCount;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: MetricTile(label: 'Strength', value: '$completionPercent%', tone: ProfileTone.primary)),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: MetricTile(label: 'Photos', value: '$photoCount/$maxPhotos', tone: ProfileTone.secondary)),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: MetricTile(label: 'Interests', value: '$interestCount', tone: ProfileTone.warm)),
    ]);
  }
}

// ── Completion section ───────────────────────────────────────────────────

class ProfileCompletionSection extends StatelessWidget {
  const ProfileCompletionSection({
    required this.completionPercent,
    required this.tips,
    super.key,
  });

  final int completionPercent;
  final List<CompletionTipData> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border), boxShadow: AppShadows.warmXs,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Profile strength', style: AppTypography.h3),
          Text('$completionPercent%', style: AppTypography.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadius.borderFull,
          child: SizedBox(height: 6, child: Stack(children: [
            Container(color: AppColors.subtle),
            FractionallySizedBox(
              widthFactor: completionPercent / 100,
              child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]))),
            ),
          ])),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: CompletionTip(label: tip.label, actionLabel: tip.actionLabel, boost: tip.boost, onTap: tip.onTap),
        )),
      ]),
    );
  }
}

/// Data holder for a completion tip.
class CompletionTipData {
  const CompletionTipData({required this.label, required this.actionLabel, required this.boost, required this.onTap});
  final String label;
  final String actionLabel;
  final String boost;
  final VoidCallback onTap;
}

// ── Photos section ───────────────────────────────────────────────────────

class ProfilePhotosSection extends StatelessWidget {
  const ProfilePhotosSection({required this.gallery, required this.displayName, super.key});
  final List<String> gallery;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final String titleSuffix = gallery.isNotEmpty ? ' (${gallery.length}/$maxPhotos)' : '';
    return SectionCard(
      title: 'Photos$titleSuffix',
      actionLabel: gallery.isNotEmpty ? 'Manage' : 'Add photos',
      onAction: () { /* TODO(#124): Open photos sheet */ },
      child: PhotoGrid(
        gallery: gallery,
        maxPhotoCount: maxPhotos,
        onPhotoTap: (index) => PhotoLightbox.show(context, photoUrls: gallery, initialIndex: index),
        onAddPhoto: () { /* TODO(#124): Open photos sheet */ },
      ),
    );
  }
}

// ── About section ────────────────────────────────────────────────────────

class ProfileAboutSection extends StatelessWidget {
  const ProfileAboutSection({required this.bio, required this.hasBio, required this.snapshotItems, super.key});
  final String bio;
  final bool hasBio;
  final List<FactRowData> snapshotItems;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SectionCard(
        title: 'About me',
        actionLabel: hasBio ? 'Edit' : 'Add intro',
        onAction: () { /* TODO(#124) */ },
        child: hasBio
            ? Container(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.primary, width: 3))),
                child: Text(bio, style: AppTypography.body.copyWith(height: 1.9)),
              )
            : EmptyPrompt(
                text: 'Share a few lines about your story, daily routine, or what matters to you.',
                actionLabel: 'Write your intro',
                onAction: () { /* TODO(#124) */ },
              ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SectionCard(
        title: 'Profile snapshot',
        actionLabel: 'Edit',
        onAction: () { /* TODO(#124) */ },
        child: snapshotItems.isNotEmpty
            ? Column(children: [
                for (int i = 0; i < snapshotItems.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  FactRow(icon: snapshotItems[i].icon, label: snapshotItems[i].label, value: snapshotItems[i].value, tone: _factTones[i % _factTones.length]),
                ],
              ])
            : EmptyPrompt(text: 'Add basics like your location, age, and what you are looking for.', actionLabel: 'Complete basics', onAction: () { /* TODO(#124) */ }),
      ),
    ]);
  }
}

// ── Interests section ────────────────────────────────────────────────────

class ProfileInterestsSection extends StatelessWidget {
  const ProfileInterestsSection({required this.interests, required this.hasInterests, required this.detailItems, super.key});
  final List<String> interests;
  final bool hasInterests;
  final List<FactRowData> detailItems;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SectionCard(
        title: 'Interests',
        actionLabel: hasInterests ? 'Edit' : 'Add interests',
        onAction: () { /* TODO(#124) */ },
        child: hasInterests
            ? Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                for (int i = 0; i < interests.length; i++)
                  InterestChip(label: interests[i], tone: _interestTones[i % _interestTones.length]),
              ])
            : EmptyPrompt(text: 'Add a few hobbies so people have natural conversation starters.', actionLabel: 'Choose interests', onAction: () { /* TODO(#124) */ }),
      ),
      const SizedBox(height: AppSpacing.sm),
      SectionCard(
        title: 'More details',
        actionLabel: 'Edit',
        onAction: () { /* TODO(#124) */ },
        child: detailItems.isNotEmpty
            ? Column(children: [
                for (int i = 0; i < detailItems.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  FactRow(icon: detailItems[i].icon, label: detailItems[i].label, value: detailItems[i].value,
                    tone: [ProfileTone.warm, ProfileTone.primary, ProfileTone.secondary][i % 3]),
                ],
              ])
            : EmptyPrompt(text: 'Add details like hobbies, education, languages, or family information.', actionLabel: 'Add details', onAction: () { /* TODO(#124) */ }),
      ),
    ]);
  }
}

/// Data holder for a snapshot/detail fact row.
class FactRowData {
  const FactRowData({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

// ── Builder functions ────────────────────────────────────────────────────

/// Builds snapshot items (location, age, gender, looking for).
List<FactRowData> buildSnapshotItems({
  required String displayLocation,
  required int? age,
  required String? gender,
  required String? lookingFor,
}) {
  return [
    if (displayLocation.isNotEmpty) FactRowData(icon: PhosphorIconsFill.mapPin, label: 'Location', value: displayLocation),
    if (age != null) FactRowData(icon: PhosphorIconsFill.calendar, label: 'Age', value: '$age years old'),
    if (gender != null) FactRowData(icon: PhosphorIconsFill.users, label: 'Gender', value: gender),
    if (lookingFor != null) FactRowData(icon: PhosphorIconsFill.heart, label: 'Looking for', value: lookingFor),
  ];
}

/// Builds detail items (hobby, civil status, religion, etc.).
List<FactRowData> buildDetailItems(UserProfile profile) {
  return [
    if (profile.hobby != null && profile.hobby!.trim().isNotEmpty)
      FactRowData(icon: PhosphorIconsFill.heart, label: 'Hobby', value: profile.hobby!.trim()),
    if (profile.civilStatus != null && profile.civilStatus!.trim().isNotEmpty)
      FactRowData(icon: PhosphorIconsFill.users, label: 'Civil status', value: ProfileHelpers.toTitleCase(profile.civilStatus!.replaceAll('_', ' '))),
    if (profile.religion != null && profile.religion!.trim().isNotEmpty)
      FactRowData(icon: PhosphorIconsFill.heart, label: 'Religion', value: profile.religion!.trim()),
    if (profile.maritalStatus != null && profile.maritalStatus!.trim().isNotEmpty)
      FactRowData(icon: PhosphorIconsFill.users, label: 'Marital status', value: ProfileHelpers.toTitleCase(profile.maritalStatus!.replaceAll('_', ' '))),
    if (profile.languages.isNotEmpty)
      FactRowData(icon: PhosphorIconsFill.translate, label: 'Languages', value: profile.languages.join(', ')),
    if (profile.numberOfChildren != null)
      FactRowData(icon: PhosphorIconsFill.users, label: 'Children', value: '${profile.numberOfChildren}'),
  ];
}

/// Builds completion tip list.
List<CompletionTipData> buildCompletionTips({
  required bool hasBio,
  required int photoCount,
  required int interestCount,
  required bool hasGender,
}) {
  return [
    if (!hasBio) CompletionTipData(label: 'Write a short introduction', actionLabel: 'Add bio', boost: '+20%', onTap: () { /* TODO(#124) */ }),
    if (photoCount < minPhotosForBonus) CompletionTipData(label: 'Add more photos', actionLabel: 'Upload', boost: '+20%', onTap: () { /* TODO(#124) */ }),
    if (interestCount < minInterestsForCompletion) CompletionTipData(label: 'Add interests', actionLabel: 'Choose', boost: '+15%', onTap: () { /* TODO(#124) */ }),
    if (!hasGender) CompletionTipData(label: 'Complete the basics', actionLabel: 'Update', boost: '+10%', onTap: () { /* TODO(#124) */ }),
  ];
}
