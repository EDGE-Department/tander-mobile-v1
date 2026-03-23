/// Full-screen profile modal overlay -- pixel-perfect port of
/// `tander-web/src/shared/ui/profile-view-modal.tsx`.
///
/// On mobile: slides up as a bottom sheet covering 94% of screen.
/// On desktop (>= 1024): slides in from the right as a 480px side panel.
///
/// Usage:
/// ```dart
/// showProfileViewModal(context, userId: '42');
/// ```
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/discover/presentation/notifiers/discover_notifier.dart';
import 'package:tander_flutter_v3/shared/widgets/photo_lightbox.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_content.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

const double _desktopBreakpoint = 1024;
const double _desktopPanelWidth = 480;
const double _mobileMaxHeightFraction = 0.94;

// ── Public API ────────────────────────────────────────────────────────────

/// Opens a profile detail overlay matching the web's `ProfileModal`.
Future<void> showProfileViewModal(
  BuildContext context, {
  required String userId,
  ProfileRelationship relationship = ProfileRelationship.none,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
  if (isDesktop) {
    return _showDesktopPanel(context, userId: userId, relationship: relationship);
  }
  return _showMobileSheet(context, userId: userId, relationship: relationship);
}

// ── Mobile: bottom sheet ──────────────────────────────────────────────────

Future<void> _showMobileSheet(
  BuildContext context, {
  required String userId,
  required ProfileRelationship relationship,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (_) => _MobileSheetWrapper(userId: userId, relationship: relationship),
  );
}

class _MobileSheetWrapper extends StatelessWidget {
  const _MobileSheetWrapper({required this.userId, required this.relationship});
  final String userId;
  final ProfileRelationship relationship;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * _mobileMaxHeightFraction;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _ProfileModalBody(userId: userId, relationship: relationship),
        ),
      ),
    );
  }
}

// ── Desktop: right-side panel ────────────────────────────────────────────

Future<void> _showDesktopPanel(
  BuildContext context, {
  required String userId,
  required ProfileRelationship relationship,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close profile',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: AppDurations.entrance,
    pageBuilder: (_, _, _) =>
        _DesktopPanelWrapper(userId: userId, relationship: relationship),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.premiumEase);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(curved),
        child: child,
      );
    },
  );
}

class _DesktopPanelWrapper extends StatelessWidget {
  const _DesktopPanelWrapper({required this.userId, required this.relationship});
  final String userId;
  final ProfileRelationship relationship;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _desktopPanelWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.card,
            boxShadow: [
              BoxShadow(color: Color(0x3D000000), blurRadius: 32, offset: Offset(-8, 0)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            left: false,
            right: false,
            child: _ProfileModalBody(userId: userId, relationship: relationship),
          ),
        ),
      ),
    );
  }
}

// ── Shared modal body ─────────────────────────────────────────────────────

class _ProfileModalBody extends ConsumerStatefulWidget {
  const _ProfileModalBody({required this.userId, required this.relationship});
  final String userId;
  final ProfileRelationship relationship;

  @override
  ConsumerState<_ProfileModalBody> createState() => _ProfileModalBodyState();
}

class _ProfileModalBodyState extends ConsumerState<_ProfileModalBody> {
  late ProfileRelationship _localRelationship;
  bool _isSendingRequest = false;

  @override
  void initState() {
    super.initState();
    _localRelationship = widget.relationship;
  }

  List<String> _buildPhotoList(DiscoveryCandidate candidate) {
    return [
      if (candidate.profilePhotoUrl != null && candidate.profilePhotoUrl!.isNotEmpty)
        candidate.profilePhotoUrl!,
      ...candidate.additionalPhotos,
    ];
  }

  void _handleClose() => Navigator.of(context).pop();

  void _handlePhotoTap(int index, List<String> allPhotos) {
    if (allPhotos.isEmpty) return;
    PhotoLightbox.show(context, photoUrls: allPhotos, initialIndex: index);
  }

  Future<void> _handleConnect() async {
    setState(() => _isSendingRequest = true);
    try {
      await ref.read(discoverNotifierProvider.notifier).likeCurrentProfile();
      if (mounted) {
        setState(() => _localRelationship = ProfileRelationship.pendingOutgoing);
      }
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  void _handleMessage() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(
      discoverProfileProvider(int.parse(widget.userId)),
    );

    return profileAsync.when(
      loading: () => const _ProfileModalSkeleton(),
      error: (_, _) => _ProfileModalError(onClose: _handleClose),
      data: (candidate) {
        final allPhotos = _buildPhotoList(candidate);
        return ProfileViewContent(
          profile: _candidateToUserProfile(candidate),
          relationship: _localRelationship,
          isSendingRequest: _isSendingRequest,
          onClose: _handleClose,
          onPhotoTap: (index) => _handlePhotoTap(index, allPhotos),
          onMessage: _handleMessage,
          onConnect: _handleConnect,
        );
      },
    );
  }
}

// ── Candidate adapter ─────────────────────────────────────────────────────

UserProfile _candidateToUserProfile(DiscoveryCandidate candidate) {
  return UserProfile(
    userId: candidate.userId,
    username: candidate.username,
    firstName: candidate.firstName,
    age: candidate.age,
    city: candidate.city,
    country: candidate.country,
    bio: candidate.bio,
    profilePhotoUrl: candidate.profilePhotoUrl,
    additionalPhotos: candidate.additionalPhotos,
    interests: candidate.interests,
    isOnline: candidate.isOnline,
    isVerified: false,
    isProfileCompleted: true,
    languages: const [],
    lookingFor: const [],
  );
}

// ── Loading skeleton ──────────────────────────────────────────────────────

class _ProfileModalSkeleton extends StatelessWidget {
  const _ProfileModalSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      AspectRatio(
        aspectRatio: 4 / 5,
        child: SkeletonCard(variant: SkeletonVariant.fullCard),
      ),
      Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(children: [
          SkeletonCard(variant: SkeletonVariant.title),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(variant: SkeletonVariant.text),
          SizedBox(height: AppSpacing.sm),
          SkeletonCard(variant: SkeletonVariant.text),
        ]),
      ),
    ]);
  }
}

// ── Error state ───────────────────────────────────────────────────────────

class _ProfileModalError extends StatelessWidget {
  const _ProfileModalError({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.dangerLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.people, size: 28, color: AppColors.danger),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Could not load this profile',
          style: AppTypography.label.copyWith(color: AppColors.textStrong),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Please check your connection and try again.',
          style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: onClose,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.subtle,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'Close',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }
}
