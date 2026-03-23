/// Reusable widget for displaying any user's profile in a scrollable view.
///
/// Used by both the profile view modal and the full-page user profile screen.
/// The photo hero and action button live in `profile_view_hero.dart`.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_hero.dart';

// ── Relationship type ────────────────────────────────────────────────────

/// Describes the connection state between the viewer and the profile owner.
enum ProfileRelationship { connected, pendingOutgoing, none }

// ── Main widget ──────────────────────────────────────────────────────────

class ProfileViewContent extends StatelessWidget {
  const ProfileViewContent({
    required this.profile,
    required this.relationship,
    required this.isSendingRequest,
    required this.onClose,
    required this.onPhotoTap,
    required this.onMessage,
    required this.onConnect,
    super.key,
  });

  final UserProfile profile;
  final ProfileRelationship relationship;
  final bool isSendingRequest;
  final VoidCallback onClose;
  final ValueChanged<int> onPhotoTap;
  final VoidCallback onMessage;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final bool hasMainPhoto =
        profile.profilePhotoUrl != null && profile.profilePhotoUrl!.isNotEmpty;
    final displayLocation = [profile.city, profile.country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
    final displayAge = profile.age != null ? '${profile.age}' : null;
    final int allPhotoCount =
        profile.additionalPhotos.length + (hasMainPhoto ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileViewHero(
          photoUrl: hasMainPhoto ? profile.profilePhotoUrl : null,
          firstName: profile.firstName,
          displayAge: displayAge,
          displayLocation: displayLocation,
          isOnline: profile.isOnline,
          isVerified: profile.isVerified,
          allPhotoCount: allPhotoCount,
          onClose: onClose,
          onPhotoTap: () => onPhotoTap(0),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: ProfileViewActionButton(
                    relationship: relationship,
                    firstName: profile.firstName,
                    isSendingRequest: isSendingRequest,
                    onMessage: onMessage,
                    onConnect: onConnect,
                  ),
                ),
                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  _SectionBlock(
                    label: 'About',
                    child: Text(
                      profile.bio!,
                      style: AppTypography.body.copyWith(height: 1.6),
                    ),
                  ),
                // Detail chips
                _DetailChips(profile: profile),
                // Interests
                if (profile.interests.isNotEmpty)
                  _SectionBlock(
                    label: 'Interests',
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: profile.interests
                          .map((interest) => _interestPill(interest))
                          .toList(),
                    ),
                  ),
                // Additional photos
                if (profile.additionalPhotos.isNotEmpty)
                  _SectionBlock(
                    label: 'Photos',
                    child: _AdditionalPhotoGrid(
                      photos: profile.additionalPhotos,
                      onPhotoTap: (index) => onPhotoTap(index + 1),
                    ),
                  ),
                // Empty state
                if (_isProfileEmpty) _emptyState(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get _isProfileEmpty =>
      profile.bio == null &&
      profile.interests.isEmpty &&
      profile.additionalPhotos.isEmpty;

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: Text(
          "${profile.firstName} hasn't filled in their profile yet.",
          style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _interestPill(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        interest,
        style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Section block ────────────────────────────────────────────────────────

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// ── Detail chips ─────────────────────────────────────────────────────────

class _DetailChips extends StatelessWidget {
  const _DetailChips({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final chips = _buildChipList();
    if (chips.isEmpty) return const SizedBox.shrink();

    return _SectionBlock(
      label: 'Details',
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips.map((chip) => _chipWidget(chip)).toList(),
      ),
    );
  }

  Widget _chipWidget(_ChipData chip) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.subtle.withValues(alpha: 0.6),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.borderSm,
            ),
            alignment: Alignment.center,
            child: Icon(chip.icon, size: 13, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chip.label.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                chip.value,
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_ChipData> _buildChipList() {
    final List<_ChipData> chips = [];
    if (profile.age != null) {
      chips.add(_ChipData(Icons.calendar_today, 'Age', '${profile.age} years old'));
    }
    if (profile.city != null || profile.country != null) {
      chips.add(_ChipData(
        Icons.language,
        'Location',
        [profile.city, profile.country].where((p) => p != null && p.trim().isNotEmpty).join(', '),
      ));
    }
    if (profile.religion != null && profile.religion!.isNotEmpty) {
      chips.add(_ChipData(Icons.church, 'Religion', profile.religion!));
    }
    if (profile.civilStatus != null && profile.civilStatus!.isNotEmpty) {
      chips.add(_ChipData(Icons.favorite, 'Civil Status', profile.civilStatus!));
    }
    if (profile.languages.isNotEmpty) {
      chips.add(_ChipData(Icons.translate, 'Languages', profile.languages.join(', ')));
    }
    if (profile.maritalStatus != null && profile.maritalStatus!.isNotEmpty) {
      chips.add(_ChipData(Icons.favorite, 'Status', profile.maritalStatus!));
    }
    if (profile.numberOfChildren != null) {
      chips.add(_ChipData(Icons.child_care, 'Children',
          profile.numberOfChildren == 0 ? 'None' : '${profile.numberOfChildren}'));
    }
    if (profile.lookingFor.isNotEmpty) {
      chips.add(_ChipData(Icons.work_outline, 'Looking for', profile.lookingFor.join(', ')));
    }
    return chips;
  }
}

class _ChipData {
  const _ChipData(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

// ── Additional photo grid ────────────────────────────────────────────────

class _AdditionalPhotoGrid extends StatelessWidget {
  const _AdditionalPhotoGrid({required this.photos, required this.onPhotoTap});
  final List<String> photos;
  final ValueChanged<int> onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onPhotoTap(index),
          child: ClipRRect(
            borderRadius: AppRadius.borderMd,
            child: CachedNetworkImage(
              imageUrl: photos[index],
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.subtle),
              errorWidget: (_, _, _) => Container(
                color: AppColors.subtle,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
              ),
            ),
          ),
        );
      },
    );
  }
}
