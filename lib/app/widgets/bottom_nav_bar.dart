import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_parts.dart';
import 'package:tander_flutter_v3/app/widgets/nav_badge_provider.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ── Tab descriptors ─────────────────────────────────────────────────────────

const List<NavTabDescriptor> navTabs = [
  NavTabDescriptor(
    id: 'discover',
    label: 'Discover',
    route: AppRoutes.discover,
    iconData: Icons.explore_outlined,
    activeIconData: Icons.explore,
    iconColor: Color(0xFF89B8E8),
  ),
  NavTabDescriptor(
    id: 'connections',
    label: 'Connect',
    route: AppRoutes.connection,
    iconAsset: 'assets/icons/matches_icon.png',
  ),
  NavTabDescriptor(
    id: 'messages',
    label: 'Chat',
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

/// Branded bottom dock nav with warm glass morphism, animated active pill,
/// Tandy teal pulse, unread badges, and staggered entrance.
///
/// Pixel-perfect copy of the web MobileBottomDock component:
/// - Pill shape: rounded-[28px]
/// - Glass: backdrop blur(48px) saturate(200%), rgba(255,252,248,0.97)
/// - 5 column tabs, min 58x58px touch targets
/// - Organic blob active pill with bloom halo
/// - Tandy teal pulse ring on inactive Tandy tab
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

  @override
  void initState() {
    super.initState();

    _tandyPulseController = AnimationController(
      vsync: this,
      duration: NavBarConstants.tandyPulseDuration,
    )..repeat();

    _tandyPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 8.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 8.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 42,
      ),
    ]).animate(_tandyPulseController);

    _entranceController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            NavBarConstants.entranceInitialDelay.inMilliseconds +
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

    final bottomInset = math.max(viewPadding.bottom, 8.0);

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 48,
              offset: const Offset(0, 16),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Row(
                children: List.generate(navTabs.length, (index) {
                  return Expanded(
                    child: NavTabEntrance(
                      delay: Duration(
                        milliseconds:
                            NavBarConstants
                                .entranceInitialDelay
                                .inMilliseconds +
                            (NavBarConstants.staggerDelay.inMilliseconds *
                                index),
                      ),
                      entranceController: _entranceController,
                      child: _MobileDockTab(
                        descriptor: navTabs[index],
                        isActive: index == activeIndex,
                        badge: _badgeForTab(navTabs[index].id, badgeCounts),
                        tandyPulseAnimation: _tandyPulseAnimation,
                        onTap: () => _onTabTapped(index),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single mobile dock tab ──────────────────────────────────────────────────

/// A single tab in the bottom dock — vertical column layout with
/// icon (30x30 container) + label, min 58x58 touch target.
class _MobileDockTab extends StatelessWidget {
  const _MobileDockTab({
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: NavBarConstants.tabMinSize,
            minWidth: NavBarConstants.tabMinSize,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Active pill — iOS 26 glassy style
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 16.0 : 10.0,
                  vertical: isActive ? 8.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  // Solid orange gradient pill matching web's ACTIVE_PILL_STYLE
                  color: isActive ? const Color(0xFFE67E22) : null,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                      ? Border.all(
                          color: Colors.white.withAlpha(80),
                          width: 0.5,
                        )
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF07020).withAlpha(50),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 32,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: descriptor.usesIconData
                                ? Icon(
                                    isActive
                                        ? (descriptor.activeIconData ??
                                              descriptor.iconData!)
                                        : descriptor.iconData!,
                                    size: 26,
                                    color: isActive
                                        ? Colors.white
                                        : (descriptor.iconColor ??
                                              AppColors.textMuted),
                                  )
                                : Image.asset(
                                    descriptor.iconAsset!,
                                    width: 30,
                                    height: 30,
                                    color: isActive ? Colors.white : null,
                                    colorBlendMode: isActive
                                        ? BlendMode.srcIn
                                        : null,
                                    opacity: AlwaysStoppedAnimation(
                                      isActive ? 1.0 : 0.9,
                                    ),
                                  ),
                          ),
                          if (badge > 0)
                            Positioned(
                              top: -5,
                              right: -5,
                              child: NavUnreadBadge(count: badge),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descriptor.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF6B5B4F),
                        height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
