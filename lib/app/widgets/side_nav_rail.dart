import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_parts.dart';
import 'package:tander_flutter_v3/app/widgets/nav_badge_provider.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';

// ── Side navigation rail ────────────────────────────────────────────────────

/// Glass-morphism side navigation rail for tablet layout.
/// Same 5 icons, same active styling as the bottom dock, but vertical.
class SideNavRail extends StatelessWidget {
  const SideNavRail({
    required this.activeIndex,
    required this.badgeCounts,
    required this.tandyPulseAnimation,
    required this.topPadding,
    required this.bottomPadding,
    required this.onTabTapped,
    super.key,
  });

  final int activeIndex;
  final NavBadgeCounts badgeCounts;
  final Animation<double> tandyPulseAnimation;
  final double topPadding;
  final double bottomPadding;
  final ValueChanged<int> onTabTapped;

  int _badgeForTab(String tabId) {
    if (tabId == 'messages') return badgeCounts.unreadMessageCount;
    if (tabId == 'connections') return badgeCounts.pendingConnectionCount;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: NavBarConstants.railBlurSigma,
          sigmaY: NavBarConstants.railBlurSigma,
        ),
        child: Container(
          width: NavBarConstants.railWidth,
          decoration: const BoxDecoration(
            color: NavBarConstants.railBackground,
            border: Border(
              right: BorderSide(color: NavBarConstants.railBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x12E67E22),
                blurRadius: 40,
                offset: Offset(4, 0),
              ),
            ],
          ),
          child: SafeArea(
            right: false,
            child: Column(
              children: [
                SizedBox(height: math.max(topPadding, 16)),

                // Tander logo at top
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Image.asset(
                    'assets/icons/tander_logo.png',
                    width: 32,
                    height: 32,
                  ),
                ),

                // Tab items
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(navTabs.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _RailTab(
                          descriptor: navTabs[index],
                          isActive: index == activeIndex,
                          badge: _badgeForTab(navTabs[index].id),
                          tandyPulseAnimation: tandyPulseAnimation,
                          onTap: () => onTabTapped(index),
                        ),
                      );
                    }),
                  ),
                ),

                SizedBox(height: math.max(bottomPadding, 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single rail tab ─────────────────────────────────────────────────────────

class _RailTab extends StatelessWidget {
  const _RailTab({
    required this.descriptor,
    required this.isActive,
    required this.badge,
    required this.tandyPulseAnimation,
    required this.onTap,
  });

  final NavTabDescriptor descriptor;
  final bool isActive;
  final int badge;
  final Animation<double> tandyPulseAnimation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: badge > 0
          ? '${descriptor.label}, $badge unread'
          : descriptor.label,
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: NavBarConstants.railTabSize,
          height: NavBarConstants.railTabSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Active pill background
              AnimatedContainer(
                duration: NavBarConstants.pillAnimationDuration,
                curve: Curves.easeOutBack,
                width: NavBarConstants.railTabSize,
                height: NavBarConstants.railTabSize,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? NavBarConstants.activePillGradient
                      : null,
                  borderRadius: isActive
                      ? NavBarConstants.activePillBorderRadius
                      : BorderRadius.circular(16),
                  boxShadow:
                      isActive ? NavBarConstants.activePillShadows : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RailTabIcon(
                      descriptor: descriptor,
                      isActive: isActive,
                      badge: badge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descriptor.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.textInverse
                            : AppColors.textMuted,
                        height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Tandy pulse on inactive
              if (descriptor.isTandy && !isActive)
                Positioned.fill(
                  child: _RailTandyPulse(animation: tandyPulseAnimation),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Rail tab icon ───────────────────────────────────────────────────────────

class _RailTabIcon extends StatelessWidget {
  const _RailTabIcon({
    required this.descriptor,
    required this.isActive,
    required this.badge,
  });

  final NavTabDescriptor descriptor;
  final bool isActive;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Image.asset(
              descriptor.iconAsset,
              width: 22,
              height: 22,
              color: isActive ? AppColors.textInverse : null,
              colorBlendMode: isActive ? BlendMode.srcIn : null,
              opacity: AlwaysStoppedAnimation(isActive ? 1.0 : 0.62),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -6,
              right: -5,
              child: NavUnreadBadge(count: badge),
            ),
        ],
      ),
    );
  }
}

// ── Rail tandy pulse ────────────────────────────────────────────────────────

class _RailTandyPulse extends StatelessWidget {
  const _RailTandyPulse({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double spread = animation.value;
        final double opacity = (1.0 - (spread / 8.0)).clamp(0.0, 0.54);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: opacity),
                blurRadius: 0,
                spreadRadius: spread,
              ),
            ],
          ),
        );
      },
    );
  }
}
