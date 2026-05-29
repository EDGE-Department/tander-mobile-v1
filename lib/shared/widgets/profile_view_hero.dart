/// Photo hero and action button for the shared profile view.
///
/// Extracted from `profile_view_content.dart` to keep each file
/// under 400 lines.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_content.dart';

/// Full-bleed photo hero with gradient overlay, name, and metadata.
class ProfileViewHero extends StatelessWidget {
  const ProfileViewHero({
    required this.photoUrl,
    required this.firstName,
    required this.displayAge,
    required this.displayLocation,
    required this.isOnline,
    required this.isVerified,
    required this.allPhotoCount,
    required this.onClose,
    required this.onPhotoTap,
    super.key,
  });

  final String? photoUrl;
  final String firstName;
  final String? displayAge;
  final String displayLocation;
  final bool isOnline;
  final bool isVerified;
  final int allPhotoCount;
  final VoidCallback onClose;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    // Web: aspect-ratio 4/5 but capped at max-height 56dvh
    final maxHeroHeight = MediaQuery.sizeOf(context).height * 0.56;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeroHeight),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              GestureDetector(
                onTap: onPhotoTap,
                child: Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholderBackground(),
                ),
              )
            else
              _placeholderBackground(),
            _gradientOverlay(),
            _closeButton(onClose),
            if (allPhotoCount > 1) _photoCounter(allPhotoCount),
            _nameOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.7, -1),
          end: Alignment(0.7, 1),
          colors: [Color(0x26E67E22), Color(0x1A0F9D94)],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.people, size: 48, color: AppColors.primary),
      ),
    );
  }

  Widget _gradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.18, 0.65, 1.0],
            colors: [
              Colors.black.withValues(alpha: 0.35),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _closeButton(VoidCallback onClose) {
    return Positioned(
      top: AppSpacing.md,
      right: AppSpacing.md,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            width: AppSpacing.touchMinimum,
            height: AppSpacing.touchMinimum,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.textInverse,
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoCounter(int count) {
    return Positioned(
      top: AppSpacing.md,
      left: AppSpacing.md,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: AppRadius.borderFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.zoom_in, size: 12, color: AppColors.textInverse),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '1 / $count',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textInverse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOnline) _onlineBadge(),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: firstName,
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (displayAge != null)
                    TextSpan(
                      text: ', $displayAge',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.textInverse.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (displayLocation.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 13,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Flexible(
                    child: Text(
                      displayLocation,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textInverse.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (isVerified) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderFull,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 11,
                      color: AppColors.textInverse,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Verified',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _onlineBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.2),
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'Online now',
              style: AppTypography.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contextual action button that changes based on [ProfileRelationship].
class ProfileViewActionButton extends StatelessWidget {
  const ProfileViewActionButton({
    required this.relationship,
    required this.firstName,
    required this.isSendingRequest,
    required this.onMessage,
    required this.onConnect,
    super.key,
  });

  final ProfileRelationship relationship;
  final String firstName;
  final bool isSendingRequest;
  final VoidCallback onMessage;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return switch (relationship) {
      ProfileRelationship.connected => _gradientButton(
        icon: Icons.chat_bubble_outline,
        label: 'Message',
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9D94), Color(0xFF0A7C74)],
        ),
        onTap: onMessage,
      ),
      ProfileRelationship.pendingOutgoing => Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
        decoration: BoxDecoration(
          color: AppColors.subtle,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Request Pending',
              style: AppTypography.label.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      ProfileRelationship.none => _gradientButton(
        icon: Icons.person_add,
        label: isSendingRequest ? 'Sending...' : 'Connect with $firstName',
        gradient: const LinearGradient(
          colors: [Color(0xFFF07020), Color(0xFFE67E22)],
        ),
        onTap: isSendingRequest ? null : onConnect,
        isDisabled: isSendingRequest,
      ),
    };
  }

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppRadius.borderLg,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.textInverse),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
