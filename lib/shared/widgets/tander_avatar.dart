import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Available avatar sizes with corresponding pixel dimensions.
///
/// xs=28, sm=36, md=48, lg=64, xl=80, xxl=112.
enum TanderAvatarSize {
  xs(28),
  sm(36),
  md(48),
  lg(64),
  xl(80),
  xxl(112);

  const TanderAvatarSize(this.diameter);

  /// Pixel diameter for this avatar size.
  final double diameter;

  /// Online-indicator dot diameter for this avatar size.
  double get onlineDotSize => switch (this) {
        TanderAvatarSize.xs => 6.0,
        TanderAvatarSize.sm => 7.0,
        TanderAvatarSize.md => 9.0,
        TanderAvatarSize.lg => 10.0,
        TanderAvatarSize.xl => 12.0,
        TanderAvatarSize.xxl => 14.0,
      };

  /// Font size for fallback initials, scaled to the avatar diameter.
  double get initialsFontSize => diameter * 0.36;
}

/// Circular avatar showing a network image or name-based initials fallback.
///
/// Optionally renders a pulsing green online indicator at the bottom-right.
class TanderAvatar extends StatelessWidget {
  const TanderAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.size = TanderAvatarSize.md,
    this.isOnline = false,
    this.showOnlineIndicator = false,
  });

  /// Remote image URL. When `null` or empty, initials are shown instead.
  final String? imageUrl;

  /// Full display name used to derive fallback initials (first + last).
  final String? displayName;

  /// Controls the avatar diameter and related proportions.
  final TanderAvatarSize size;

  /// Whether the user is currently online (drives the dot color).
  final bool isOnline;

  /// Whether to render the online-indicator dot at all.
  final bool showOnlineIndicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.diameter,
      height: size.diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildAvatar(),
          if (showOnlineIndicator && isOnline) _buildOnlineDot(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size.diameter,
      height: size.diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight, width: 2),
      ),
      child: ClipOval(
        child: hasImage ? _networkImage() : _initialsFallback(),
      ),
    );
  }

  Widget _networkImage() {
    return Image.network(
                  imageUrl!,
      width: size.diameter,
      height: size.diameter,
      fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initialsFallback(),
    );
  }

  Widget _initialsFallback() {
    return Container(
      width: size.diameter,
      height: size.diameter,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF0E0), Color(0xFFFDE8CC)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTypography.label.copyWith(
          fontSize: size.initialsFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildOnlineDot() {
    final double dotSize = size.onlineDotSize;
    const double borderWidth = 2;

    return Positioned(
      right: 0,
      bottom: 0,
      child: _PulsingOnlineDot(dotSize: dotSize, borderWidth: borderWidth),
    );
  }

  String get _initials {
    if (displayName == null || displayName!.trim().isEmpty) {
      return '?';
    }

    final List<String> nameParts =
        displayName!.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

    if (nameParts.isEmpty) return '?';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();

    return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
  }
}

/// Pulsing green dot that indicates an online user.
///
/// Uses a repeating scale animation to draw attention.
class _PulsingOnlineDot extends StatefulWidget {
  const _PulsingOnlineDot({
    required this.dotSize,
    required this.borderWidth,
  });

  final double dotSize;
  final double borderWidth;

  @override
  State<_PulsingOnlineDot> createState() => _PulsingOnlineDotState();
}

class _PulsingOnlineDotState extends State<_PulsingOnlineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (_, Widget? child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: widget.dotSize,
        height: widget.dotSize,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.card,
            width: widget.borderWidth,
          ),
        ),
      ),
    );
  }
}
