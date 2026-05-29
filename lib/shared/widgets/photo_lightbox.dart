import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/utils/photo_url.dart';

/// Full-screen photo viewer with swipe navigation and pinch-to-zoom.
///
/// Shows a [PageView] of network images over a black backdrop.
/// Includes a counter ("1 of 5"), close button, dot indicators,
/// and optional arrow navigation on wider screens (tablets).
///
/// Open via the static [show] helper:
/// ```dart
/// PhotoLightbox.show(context, photoUrls: urls, initialIndex: 0);
/// ```
class PhotoLightbox extends StatefulWidget {
  const PhotoLightbox({
    required this.photoUrls,
    this.initialIndex = 0,
    super.key,
  });

  /// Ordered list of image URLs to display.
  final List<String> photoUrls;

  /// Zero-based index of the first photo shown.
  final int initialIndex;

  /// Convenience method to push the lightbox as a full-screen route.
  static void show(
    BuildContext context, {
    required List<String> photoUrls,
    int initialIndex = 0,
  }) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) =>
            PhotoLightbox(photoUrls: photoUrls, initialIndex: initialIndex),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppDurations.entrance,
        reverseTransitionDuration: AppDurations.base,
      ),
    );
  }

  @override
  State<PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<PhotoLightbox> {
  late final PageController _pageController;
  late int _currentIndex;

  // ── Layout constants ─────────────────────────────────────────────

  static const double _dotActiveWidth = 20;
  static const double _dotInactiveWidth = 8;
  static const double _dotHeight = 8;
  static const double _dotSpacing = 6;
  static const double _navArrowSize = 44;
  static const double _tabletBreakpoint = 600;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.photoUrls.length) return;
    _pageController.animateToPage(
      index,
      duration: AppDurations.base,
      curve: AppCurves.premiumEase,
    );
  }

  bool get _hasPrevious => _currentIndex > 0;
  bool get _hasNext => _currentIndex < widget.photoUrls.length - 1;
  bool get _hasMultiplePhotos => widget.photoUrls.length > 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildPageView(),
            _buildTopBar(),
            if (_hasMultiplePhotos) _buildDotIndicators(),
            if (_hasMultiplePhotos) _buildTabletArrows(context),
          ],
        ),
      ),
    );
  }

  // ── Page view ────────────────────────────────────────────────────

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.photoUrls.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) => _buildZoomableImage(index),
    );
  }

  Widget _buildZoomableImage(int index) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.network(
          resolvePhotoUrl(widget.photoUrls[index]) ?? widget.photoUrls[index],
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.textInverse,
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar: counter + close ─────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_hasMultiplePhotos) _buildCounter() else const SizedBox.shrink(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    final displayIndex = _currentIndex + 1;
    final total = widget.photoUrls.length;
    return Text(
      '$displayIndex of $total',
      style: AppTypography.label.copyWith(color: AppColors.textInverse),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: const SizedBox(
        width: AppSpacing.touchMinimum,
        height: AppSpacing.touchMinimum,
        child: Center(
          child: Icon(
            Icons.close_rounded,
            color: AppColors.textInverse,
            size: 28,
          ),
        ),
      ),
    );
  }

  // ── Bottom dot indicators ────────────────────────────────────────

  Widget _buildDotIndicators() {
    return Positioned(
      bottom: AppSpacing.lg,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.photoUrls.length,
          (index) => _buildDot(isActive: index == _currentIndex),
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.premiumEase,
      margin: const EdgeInsets.symmetric(horizontal: _dotSpacing / 2),
      width: isActive ? _dotActiveWidth : _dotInactiveWidth,
      height: _dotHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_dotHeight / 2),
        color: isActive
            ? AppColors.textInverse
            : AppColors.textInverse.withAlpha(102), // 40 %
      ),
    );
  }

  // ── Tablet arrow navigation ──────────────────────────────────────

  Widget _buildTabletArrows(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < _tabletBreakpoint) return const SizedBox.shrink();

    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildArrowButton(
            icon: Icons.chevron_left_rounded,
            isEnabled: _hasPrevious,
            onTap: () => _goToPage(_currentIndex - 1),
          ),
          _buildArrowButton(
            icon: Icons.chevron_right_rounded,
            isEnabled: _hasNext,
            onTap: () => _goToPage(_currentIndex + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: isEnabled ? 1 : 0.3,
          child: Container(
            width: _navArrowSize,
            height: _navArrowSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textInverse.withAlpha(26), // 10 %
            ),
            child: Center(
              child: Icon(icon, color: AppColors.textInverse, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
