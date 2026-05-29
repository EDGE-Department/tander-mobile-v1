/// My Profile tab — pixel-faithful port of `tander-web` `ProfilePage`.
///
/// Layout (top → bottom):
///   1. ProfileHero (avatar, name, badges, stats, bio, meta pills)
///   2. Action row (Edit Profile + Settings + Help)
///   3. Gallery section (header + photo grid or empty prompt)
///   4. Bento: Your Interests | Vital Facts (stacked on phone, side-by-side
///      on tablet ≥ 768 wide)
///   5. Sign out button (white, danger-tinted, full uppercase)
///
/// The background is a fixed cream wash with a top orange→transparent
/// glow, matching the web's atmospheric layer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/notifiers/my_profile_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_photos_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/states/profile_state.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/help_sheet.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_hero.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_screen_sections.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

// Web `space-y-10` between top-level content sections on phone.
const double _kSectionGap = 40;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProfileNotifierProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(myProfileNotifierProvider);

    return _ProfileBackground(
      child: switch (profileState) {
        ProfileLoading() => _buildLoading(),
        ProfileError(:final exception) => _buildError(exception.userMessage),
        ProfileLoaded(:final profile) => ProfileLoadedBody(profile: profile),
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textBody),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(myProfileNotifierProvider.notifier).fetchProfile(),
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
          SkeletonCard(height: 280),
          SizedBox(height: 32),
          SkeletonCard(),
          SizedBox(height: 24),
          SkeletonCard(),
        ],
      ),
    );
  }
}

/// Paints the atmospheric background underneath the profile content.
///
/// Mirrors web's fixed cream base + top orange-to-transparent gradient.
class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Cream base — matches web `bg-[#FFFBF5]`.
        const Positioned.fill(child: ColoredBox(color: Color(0xFFFFFBF5))),
        // Top warm glow — web `bg-gradient-to-b from-orange-100/30 to-transparent`.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 600,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4DFFEDD5), // orange-100 @ ~30 %
                  Color(0x00FFEDD5),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Loaded state body for the profile screen.
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
          (interest) => interest.trim().length > 1 && !interest.startsWith('['),
        )
        .toList();

    final completionPercent = ProfileHelpers.computeCompletionPercent(profile);
    final isProfileComplete = completionPercent >= 100;
    final tierLabel = ProfileHelpers.completionTierLabel(completionPercent);

    final hasInterests = interests.isNotEmpty;

    final snapshotItems = buildSnapshotItems(
      displayLocation: displayLocation,
      age: profile.age,
      gender: gender,
      lookingFor: lookingFor,
    );

    return Consumer(
      builder: (context, ref, _) => RefreshIndicator.adaptive(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(myProfileNotifierProvider.notifier).fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHero(
                gallery: gallery,
                displayName: displayName,
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
                interests: interests,
                hasInterests: hasInterests,
                snapshotItems: snapshotItems,
                onEdit: () => _openEditSheet(context),
                onPhotos: () => _openPhotosSheet(context),
                onSettings: () => _openSettingsSheet(context),
                onHelp: () => showHelpSheet(context),
              ),
            ],
          ),
        ),
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
    pageBuilder: (dialogContext, _, _) {
      final screenSize = MediaQuery.sizeOf(dialogContext);
      final isTablet = screenSize.width >= 768;
      // On tablets, use a centered card with max width; on phones, use bottom sheet
      final maxWidth = isTablet ? 600.0 : screenSize.width;
      final heightFactor = isTablet ? 0.85 : 0.92;

      return Align(
        alignment: isTablet ? Alignment.center : Alignment.bottomCenter,
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(isTablet ? 24 : 0).copyWith(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: isTablet ? 8 : 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: screenSize.height * heightFactor,
            ),
            child: SizedBox(
              width: isTablet ? maxWidth : screenSize.width,
              height: screenSize.height * heightFactor,
              child: child,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
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

/// Below-the-hero stack: action row, gallery, bento, sign-out.
///
/// Horizontal padding matches web's `px-4` on mobile; sections are
/// separated by [_kSectionGap] (web `space-y-10`).
class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.gallery,
    required this.displayName,
    required this.interests,
    required this.hasInterests,
    required this.snapshotItems,
    required this.onEdit,
    required this.onPhotos,
    required this.onSettings,
    required this.onHelp,
  });

  final List<String> gallery;
  final String displayName;
  final List<String> interests;
  final bool hasInterests;
  final List<FactRowData> snapshotItems;
  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    // Always use stacked layout - simpler and works on all screen sizes.
    // Constrain max width on larger screens for readability.
    const maxContentWidth = 500.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileActionRow(
                onEdit: onEdit,
                onPhotos: onPhotos,
                onSettings: onSettings,
                onHelp: onHelp,
              ),
              const SizedBox(height: _kSectionGap),
              ProfilePhotosSection(
                gallery: gallery,
                displayName: displayName,
                onManage: onPhotos,
                onAddPhoto: onPhotos,
              ),
              const SizedBox(height: _kSectionGap),
              ProfileInterestsSection(
                interests: interests,
                hasInterests: hasInterests,
                onChooseInterests: onEdit,
              ),
              const SizedBox(height: _kSectionGap),
              ProfileVitalFactsSection(
                snapshotItems: snapshotItems,
                onAddDetails: onEdit,
              ),
              const SizedBox(height: 64),
              const _SignOutButton(),
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}

/// White, danger-tinted, full-uppercase sign-out button.
///
/// Matches web's `flex w-full h-16 ... bg-white border-2 border-danger/20 …`.
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton.icon(
        onPressed: () => _confirmAndSignOut(context, ref),
        icon: const Icon(Icons.logout, size: 22),
        label: const Text(
          'SIGN OUT FROM TANDER',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: AppColors.danger.withValues(alpha: 0.20),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  void _confirmAndSignOut(BuildContext context, WidgetRef ref) {
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
  }
}
