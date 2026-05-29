/// Full-screen page for viewing another user's profile (/user/:userId).
///
/// Reads `userId` from GoRouter path parameters, fetches the user profile,
/// and delegates rendering to the shared [ProfileViewContent] widget.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/discover/presentation/notifiers/discover_notifier.dart';
import 'package:tander_flutter_v3/features/discover/presentation/providers/discover_providers.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/providers/messaging_providers.dart';
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

    final profileAsync = ref.watch(discoverProfileProvider(userId));
    return profileAsync.when(
      loading: () => _buildLoadingState(),
      error: (error, _) =>
          _buildErrorState(context, 'Could not load this profile.'),
      data: (candidate) => UserProfileBody(
        profile: _candidateToProfile(candidate),
        userId: userId,
      ),
    );
  }

  UserProfile _candidateToProfile(DiscoveryCandidate candidate) {
    return UserProfile(
      userId: candidate.userId,
      firstName: candidate.firstName,
      isOnline: candidate.isOnline,
      isVerified: false,
      isProfileCompleted: true,
      additionalPhotos: candidate.additionalPhotos,
      interests: candidate.interests,
      lookingFor: const [],
      languages: const [],
      age: candidate.age,
      bio: candidate.bio,
      city: candidate.city,
      country: candidate.country,
      profilePhotoUrl: candidate.profilePhotoUrl,
    );
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
class UserProfileBody extends ConsumerStatefulWidget {
  const UserProfileBody({
    required this.profile,
    required this.userId,
    super.key,
  });

  final UserProfile profile;
  final String userId;

  @override
  ConsumerState<UserProfileBody> createState() => _UserProfileBodyState();
}

class _UserProfileBodyState extends ConsumerState<UserProfileBody> {
  // No caller supplies a relationship for this route (it's a deep-link target),
  // so we start at `none` and flip optimistically on a successful connect.
  // TODO: fetch the real relationship by userId when an API exists.
  ProfileRelationship _localRelationship = ProfileRelationship.none;
  bool _isSendingRequest = false;
  bool _isOpeningConversation = false;

  Future<void> _handleConnect() async {
    setState(() => _isSendingRequest = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(discoverRepositoryProvider)
          .sendConnectionRequest(targetUserId: widget.userId);
      if (!mounted) return;
      result.when(
        success: (_) {
          setState(
            () => _localRelationship = ProfileRelationship.pendingOutgoing,
          );
        },
        failure: (exception) {
          messenger.showSnackBar(
            SnackBar(content: Text(exception.userMessage)),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  void _handleMessage() {
    if (_isOpeningConversation) return;
    unawaited(_openConversation());
  }

  Future<void> _openConversation() async {
    setState(() => _isOpeningConversation = true);

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final currentUserId = ref.read(currentUserIdProvider);
    final result = await ref
        .read(messagingRepositoryProvider)
        .startConversation(
          otherUserId: widget.userId,
          currentUserId: currentUserId,
        );

    if (!mounted) return;
    setState(() => _isOpeningConversation = false);

    result.when(
      success: (conversation) {
        router.go(AppRoutes.messageThread(conversation.conversationId));
      },
      failure: (exception) {
        messenger.showSnackBar(SnackBar(content: Text(exception.userMessage)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPhotos = _buildAllPhotos(widget.profile);
    final sessionManager = ref.read(sessionManagerLateProvider);
    final currentUserId = sessionManager?.session?.userId;
    final isSelf =
        currentUserId != null && currentUserId.toString() == widget.userId;

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
              profile: widget.profile,
              relationship: _localRelationship,
              isSendingRequest: _isSendingRequest,
              isSelf: isSelf,
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
              onMessage: _handleMessage,
              onConnect: _handleConnect,
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
              icon: Icons.arrow_back,
              semanticLabel: 'Go back',
              onTap: onBack,
            ),
            _NavButton(
              icon: Icons.more_vert,
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
