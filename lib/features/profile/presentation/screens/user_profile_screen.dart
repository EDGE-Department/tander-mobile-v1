/// Full-screen page for viewing another user's profile (/user/:userId).
///
/// Reads `userId` from GoRouter path parameters, fetches the user profile,
/// and delegates rendering to the shared [ProfileViewContent] widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/photo_lightbox.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_content.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

/// Displays another user's profile from a userId route parameter.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = GoRouterState.of(context).pathParameters['userId'] ?? '';

    if (userId.isEmpty) {
      return _buildErrorState(context, 'No user ID provided.');
    }

    // TODO(#125): Wire to a real user profile provider, e.g.:
    // final profileAsync = ref.watch(userProfileProvider(userId));
    // return profileAsync.when(
    //   loading: () => _buildLoadingState(),
    //   error: (error, _) => _buildErrorState(context, 'Could not load this profile.'),
    //   data: (profile) => _UserProfileBody(profile: profile),
    // );

    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              SkeletonCard(),
              SizedBox(height: AppSpacing.md),
              SkeletonCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.discover);
                    }
                  },
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.touchMinimum,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'Go back',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders the loaded user profile with a top nav bar and content body.
class UserProfileBody extends StatelessWidget {
  const UserProfileBody({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final allPhotos = _buildAllPhotos(profile);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          // Top nav bar
          _TopNavBar(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.discover);
              }
            },
            onMore: () {
              // TODO(#126): Open block/report modal
            },
          ),
          // Profile content
          Expanded(
            child: ProfileViewContent(
              profile: profile,
              relationship: ProfileRelationship.none,
              isSendingRequest: false,
              onClose: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              onPhotoTap: (index) {
                if (allPhotos.isNotEmpty) {
                  PhotoLightbox.show(
                    context,
                    photoUrls: allPhotos,
                    initialIndex: index.clamp(0, allPhotos.length - 1),
                  );
                }
              },
              onMessage: () {
                context.go(AppRoutes.messages);
              },
              onConnect: () {
                // TODO(#127): Send connection request
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildAllPhotos(UserProfile userProfile) {
    final List<String> photos = [];
    if (userProfile.profilePhotoUrl != null &&
        userProfile.profilePhotoUrl!.isNotEmpty) {
      photos.add(userProfile.profilePhotoUrl!);
    }
    photos.addAll(userProfile.additionalPhotos);
    return photos;
  }
}

// ── Top navigation bar ───────────────────────────────────────────────────

class _TopNavBar extends StatelessWidget {
  const _TopNavBar({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              icon: PhosphorIconsBold.arrowLeft,
              semanticLabel: 'Go back',
              onTap: onBack,
            ),
            _NavButton(
              icon: PhosphorIconsBold.dotsThreeVertical,
              semanticLabel: 'More options',
              onTap: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSpacing.touchMinimum,
          height: AppSpacing.touchMinimum,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
