import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_parts.dart';
import 'package:tander_flutter_v3/app/widgets/nav_badge_provider.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ── Tab descriptors ─────────────────────────────────────────────────────────

const List<NavTabDescriptor> navTabs = [
  NavTabDescriptor(
    id: 'discover',
    label: 'Discover',
    route: AppRoutes.discover,
    iconAsset: 'assets/icons/tander_logo.png',
  ),
  NavTabDescriptor(
    id: 'connections',
    label: 'Connections',
    route: AppRoutes.connection,
    iconAsset: 'assets/icons/matches_icon.png',
  ),
  NavTabDescriptor(
    id: 'messages',
    label: 'Messages',
    route: AppRoutes.messages,
    iconAsset: 'assets/icons/messages_icon.png',
  ),
  NavTabDescriptor(
    id: 'tandy',
    label: 'Tandy',
    route: AppRoutes.tandy,
    iconAsset: 'assets/icons/tandy_icon.png',
    isTandy: true,
  ),
  NavTabDescriptor(
    id: 'profile',
    label: 'Profile',
    route: AppRoutes.profile,
    iconAsset: 'assets/icons/profile_icon.png',
  ),
];

// ── TanderBottomNavBar ──────────────────────────────────────────────────────

/// Branded bottom navigation bar with warm glass morphism, animated active
/// pill, Tandy teal pulse ring, unread badges, and staggered entrance.
///
/// Uses [ConsumerStatefulWidget] for animation controllers (Tandy pulse,
/// entrance stagger) and Riverpod access for future badge providers.
class TanderBottomNavBar extends ConsumerStatefulWidget {
  const TanderBottomNavBar({super.key});

  @override
  ConsumerState<TanderBottomNavBar> createState() => _TanderBottomNavBarState();
}

class _TanderBottomNavBarState extends ConsumerState<TanderBottomNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _tandyPulseController;
  late final AnimationController _entranceController;
  late final Animation<double> _tandyPulseAnimation;

  // Badge counts are read from the navBadgeProvider in build().

  @override
  void initState() {
    super.initState();

    _tandyPulseController = AnimationController(
      vsync: this,
      duration: NavBarConstants.tandyPulseDuration,
    )..repeat();

    _tandyPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
    ]).animate(_tandyPulseController);

    _entranceController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: NavBarConstants.entranceInitialDelay.inMilliseconds +
            (NavBarConstants.staggerDelay.inMilliseconds * navTabs.length) +
            300,
      ),
    )..forward();
  }

  @override
  void dispose() {
    _tandyPulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  int _resolveActiveIndex(String location) {
    for (int index = 0; index < navTabs.length; index++) {
      final String route = navTabs[index].route;
      if (location == route || location.startsWith('$route/')) {
        return index;
      }
    }
    return 0;
  }

  int _badgeForTab(String tabId, NavBadgeCounts badgeCounts) {
    if (tabId == 'messages') return badgeCounts.unreadMessageCount;
    if (tabId == 'connections') return badgeCounts.pendingConnectionCount;
    return 0;
  }

  void _onTabTapped(int index) {
    context.go(navTabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int activeIndex = _resolveActiveIndex(location);
    final EdgeInsets viewPadding = MediaQuery.viewPaddingOf(context);
    final NavBadgeCounts badgeCounts = ref.watch(navBadgeProvider);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: math.max(viewPadding.bottom, AppSpacing.sm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            decoration: BoxDecoration(
              color: NavBarConstants.glassBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: NavBarConstants.glassBorder),
              boxShadow: const [NavBarConstants.containerOuterShadow],
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: NavBokehOrbs()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(navTabs.length, (index) {
                      return NavTabEntrance(
                        delay: Duration(
                          milliseconds:
                              NavBarConstants.entranceInitialDelay
                                      .inMilliseconds +
                                  (NavBarConstants.staggerDelay
                                          .inMilliseconds *
                                      index),
                        ),
                        entranceController: _entranceController,
                        child: _NavTab(
                          descriptor: navTabs[index],
                          isActive: index == activeIndex,
                          badge: _badgeForTab(navTabs[index].id, badgeCounts),
                          tandyPulseAnimation: _tandyPulseAnimation,
                          onTap: () => _onTabTapped(index),
                        ),
                      );
                    }),
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

// ── Single nav tab ──────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  const _NavTab({
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
          height: NavBarConstants.tabHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isActive)
                const Positioned(
                  left: -14,
                  right: -14,
                  top: -10,
                  bottom: -10,
                  child: NavActiveBloomHalo(),
                ),
              AnimatedContainer(
                duration: NavBarConstants.pillAnimationDuration,
                curve: Curves.easeOutBack,
                height: NavBarConstants.tabHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: NavBarConstants.tabHorizontalPadding,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isActive ? NavBarConstants.activePillGradient : null,
                  borderRadius: BorderRadius.circular(
                    NavBarConstants.tabRadius,
                  ),
                  boxShadow:
                      isActive ? const [NavBarConstants.pillShadow] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TabIcon(
                      descriptor: descriptor,
                      isActive: isActive,
                      badge: badge,
                    ),
                    const SizedBox(width: NavBarConstants.iconLabelGap),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.textInverse
                            : AppColors.textMuted,
                        height: 1,
                      ),
                      child: Text(descriptor.label),
                    ),
                  ],
                ),
              ),
              if (descriptor.isTandy && !isActive)
                Positioned.fill(
                  child: _TandyPulseRing(
                    animation: tandyPulseAnimation,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab icon with badge overlay ─────────────────────────────────────────────

class _TabIcon extends StatelessWidget {
  const _TabIcon({
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
      width: NavBarConstants.iconSize,
      height: NavBarConstants.iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: AnimatedScale(
              scale: isActive ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Image.asset(
                descriptor.iconAsset,
                width: NavBarConstants.iconSize,
                height: NavBarConstants.iconSize,
                color: isActive ? AppColors.textInverse : null,
                colorBlendMode: isActive ? BlendMode.srcIn : null,
                opacity: AlwaysStoppedAnimation(isActive ? 1.0 : 0.62),
              ),
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

// ── Tandy pulse ring ────────────────────────────────────────────────────────

class _TandyPulseRing extends StatelessWidget {
  const _TandyPulseRing({required this.animation});

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
            borderRadius: BorderRadius.circular(NavBarConstants.tabRadius),
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
