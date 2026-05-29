/// Photo carousel hero for the discover profile screen.
///
/// Extracted from discover_profile_screen.dart to keep files under 400 lines.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Full-bleed photo carousel with gradient overlay, back button, and name.
class DiscoverProfileHero extends StatelessWidget {
  const DiscoverProfileHero({
    required this.candidate,
    required this.allPhotos,
    required this.pageController,
    required this.currentPhotoPage,
    required this.onPageChanged,
    required this.onBack,
    super.key,
  });

  final DiscoveryCandidate candidate;
  final List<String> allPhotos;
  final PageController pageController;
  final int currentPhotoPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;

  static const double heroHeight = 400;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPhotoPageView(),
          _buildGradientOverlay(),
          _buildBackButton(context),
          _buildNameOverlay(),
          if (allPhotos.length > 1) _buildDotIndicators(),
        ],
      ),
    );
  }

  Widget _buildPhotoPageView() {
    if (allPhotos.isNotEmpty) {
      return PageView.builder(
        controller: pageController,
        itemCount: allPhotos.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          return Image.network(
            allPhotos[index],
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.subtle,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.7, -1),
          end: Alignment(0.7, 1),
          colors: [Color(0xFFFEF0E0), Color(0xFFE0F5F4)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: 80,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.15, 0.65, 1.0],
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      left: AppSpacing.md,
      child: GestureDetector(
        onTap: onBack,
        child: Container(
          width: AppSpacing.touchMinimum,
          height: AppSpacing.touchMinimum,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: AppRadius.borderMd,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back,
            size: 20,
            color: AppColors.textInverse,
          ),
        ),
      ),
    );
  }

  Widget _buildNameOverlay() {
    return Positioned(
      bottom: AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: candidate.firstName,
              style: AppTypography.h1.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (candidate.age != null)
              TextSpan(
                text: ', ${candidate.age}',
                style: AppTypography.h2.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w300,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Positioned(
      bottom: AppSpacing.xs,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(allPhotos.length, (index) {
          final bool isActive = index == currentPhotoPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderFull,
              color: isActive
                  ? AppColors.textInverse
                  : Colors.white.withValues(alpha: 0.4),
            ),
          );
        }),
      ),
    );
  }
}
