/// My Profile tab — the authenticated user's own profile page.
///
/// Watches [myProfileNotifierProvider] and renders the hero, actions,
/// metrics, and content sections. Section widgets live in
/// `profile_screen_sections.dart` to keep this file focused.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/notifiers/my_profile_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/states/profile_state.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/help_sheet.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_hero.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_screen_sections.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_photos_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_screen.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

/// My Profile screen displayed as a tab in the bottom navigation.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(myProfileNotifierProvider);

    return switch (profileState) {
      ProfileLoading() => _buildLoading(),
      ProfileError(:final exception) => _buildError(ref, exception.userMessage),
      ProfileLoaded(:final profile) => ProfileLoadedBody(profile: profile),
    };
  }

  Widget _buildError(WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textBody)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(myProfileNotifierProvider.notifier).fetchProfile(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
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
        .where(
          (interest) =>
              interest.trim().length > 1 && !interest.startsWith('['),
        )
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
      context: context,
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
            onChangePhoto: () => _openPhotosSheet(context),
            interestsCount: interests.length,
            bio: bio,
          ),
          _ProfileContent(
            gallery: gallery,
            displayName: displayName,
            completionPercent: completionPercent,
            isProfileComplete: isProfileComplete,
            interests: interests,
            bio: bio,
            hasBio: hasBio,
            hasInterests: hasInterests,
            snapshotItems: snapshotItems,
            detailItems: detailItems,
            completionTips: completionTips,
            onEdit: () => _openEditSheet(context),
            onPhotos: () => _openPhotosSheet(context),
            onSettings: () => _openSettingsSheet(context),
            onHelp: () => showHelpSheet(context),
          ),
        ],
      ),
    );
  }

}

// ── Modal sheet helpers — full-screen overlays that cover the nav bar ─────

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
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: child,
        ),
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

void _openEditSheet(BuildContext context) =>
    _showFullScreenSheet(context, const ProfileEditScreen());

void _openPhotosSheet(BuildContext context) =>
    _showFullScreenSheet(context, const ProfilePhotosScreen());

void _openSettingsSheet(BuildContext context) =>
    _showFullScreenSheet(context, const SettingsScreen());

/// Content sections below the hero, adapts to phone vs tablet.
class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.gallery,
    required this.displayName,
    required this.completionPercent,
    required this.isProfileComplete,
    required this.interests,
    required this.bio,
    required this.hasBio,
    required this.hasInterests,
    required this.snapshotItems,
    required this.detailItems,
    required this.completionTips,
    required this.onEdit,
    required this.onPhotos,
    required this.onSettings,
    required this.onHelp,
  });

  final List<String> gallery;
  final String displayName;
  final int completionPercent;
  final bool isProfileComplete;
  final List<String> interests;
  final String bio;
  final bool hasBio;
  final bool hasInterests;
  final List<FactRowData> snapshotItems;
  final List<FactRowData> detailItems;
  final List<CompletionTipData> completionTips;
  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileActionRow(
            onEdit: onEdit,
            onPhotos: onPhotos,
            onSettings: onSettings,
            onHelp: onHelp,
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
          const SizedBox(height: AppSpacing.lg),
          // Sign out button
          _SignOutButton(),
          const SizedBox(height: 160), // extra space so content isn't hidden behind floating nav bar
        ],
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Sign out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ).then((confirmed) {
            if (confirmed == true) {
              ref.read(authNotifierProvider.notifier).signOut();
            }
          });
        },
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
