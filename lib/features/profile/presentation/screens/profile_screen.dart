/// My Profile tab — the authenticated user's own profile page.
///
/// Watches [myProfileNotifierProvider] and renders the hero, actions,
/// metrics, and content sections. Section widgets live in
/// `profile_screen_sections.dart` to keep this file focused.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_hero.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_screen_sections.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

/// My Profile screen displayed as a tab in the bottom navigation.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(#123): Watch myProfileNotifierProvider here.
    // final profileAsync = ref.watch(myProfileNotifierProvider);
    // return profileAsync.when(
    //   loading: () => _buildLoading(),
    //   error: (error, _) => _buildError(ref),
    //   data: (profile) => ProfileLoadedBody(profile: profile),
    // );

    // Stub: show loading skeleton until the provider is wired.
    return _buildLoading();
  }

  Widget _buildLoading() {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          SkeletonCard(height: 200),
          SizedBox(height: AppSpacing.lg),
          SkeletonCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(),
        ],
      ),
    );
  }
}

/// Loaded state body for the profile screen.
///
/// Public so the screen can instantiate it once the provider is wired.
class ProfileLoadedBody extends StatelessWidget {
  const ProfileLoadedBody({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final displayName = ProfileHelpers.buildDisplayName(profile);
    final displayLocation = ProfileHelpers.buildDisplayLocation(profile);
    final gallery = ProfileHelpers.buildGallery(profile);
    final lookingFor = ProfileHelpers.formatLookingFor(profile.lookingFor);
    final bio = (profile.bio ?? '').trim();
    final gender = (profile.gender ?? '').trim().isNotEmpty
        ? ProfileHelpers.toTitleCase(profile.gender!)
        : null;
    final interests = profile.interests
        .where((interest) =>
            interest.trim().length > 1 && !interest.startsWith('['))
        .toList();

    final completionPercent =
        ProfileHelpers.computeCompletionPercent(profile);
    final isProfileComplete = completionPercent >= 100;
    final tierLabel =
        ProfileHelpers.completionTierLabel(completionPercent);

    final hasBio = bio.isNotEmpty;
    final hasInterests = interests.isNotEmpty;

    final snapshotItems = buildSnapshotItems(
      displayLocation: displayLocation,
      age: profile.age,
      gender: gender,
      lookingFor: lookingFor,
    );
    final detailItems = buildDetailItems(profile);
    final completionTips = buildCompletionTips(
      hasBio: hasBio,
      photoCount: gallery.length,
      interestCount: interests.length,
      hasGender: gender != null,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHero(
            gallery: gallery,
            displayName: displayName,
            username: profile.username,
            isOnline: profile.isOnline,
            completionPercent: completionPercent,
            isProfileComplete: isProfileComplete,
            tierLabel: tierLabel,
            isVerified: profile.isVerified,
            displayLocation: displayLocation,
            age: profile.age,
            gender: gender,
            lookingFor: lookingFor,
            onChangePhoto: _noOp,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProfileActionRow(
                  onEdit: _noOp,
                  onPhotos: _noOp,
                  onSettings: _noOp,
                  onHelp: _noOp,
                ),
                const SizedBox(height: AppSpacing.xs),
                ProfileMetricRow(
                  completionPercent: completionPercent,
                  photoCount: gallery.length,
                  interestCount: interests.length,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!isProfileComplete && completionTips.isNotEmpty) ...[
                  ProfileCompletionSection(
                    completionPercent: completionPercent,
                    tips: completionTips,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                ProfilePhotosSection(
                  gallery: gallery,
                  displayName: displayName,
                ),
                const SizedBox(height: AppSpacing.sm),
                ProfileAboutSection(
                  bio: bio,
                  hasBio: hasBio,
                  snapshotItems: snapshotItems,
                ),
                const SizedBox(height: AppSpacing.sm),
                ProfileInterestsSection(
                  interests: interests,
                  hasInterests: hasInterests,
                  detailItems: detailItems,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder callback until sheets are wired.
  static void _noOp() {
    // TODO(#124): Wire to sheet callbacks once data layer ships.
  }
}
