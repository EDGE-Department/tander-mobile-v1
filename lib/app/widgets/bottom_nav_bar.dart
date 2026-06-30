import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_parts.dart';
import 'package:tander_flutter_v3/app/widgets/nav_badge_provider.dart';
import 'package:tander_flutter_v3/app/widgets/nav_geometry.dart';
import 'package:tander_flutter_v3/app/widgets/nav_rail_indicator.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ── Tab descriptors ─────────────────────────────────────────────────────────

// Shared with the tablet/desktop [TanderTopNavBar] — keep the icon fields the
// top nav relies on. The bottom-dock redesign reads only id/label/route and
// derives its own placeholder accents from [_kAccents] below.
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

/// Bottom-dock placeholder accent per tab id (Phase 1). Phase 2 replaces the
/// placeholder boxes with the real idle/clicked icon assets.
const Map<String, Color> _kAccents = {
  'discover': Color(0xFF4F9BE8),
  'connections': Color(0xFFE85C97),
  'messages': Color(0xFFE67E22),
  'tandy': Color(0xFF4F9BE8),
  'profile': Color(0xFF8B6BE8),
};

Color _accentFor(String id) => _kAccents[id] ?? const Color(0xFF6B5B4F);

// ── Tunables (Task 7 tunes these on-device) ─────────────────────────────────

const double _kCapsuleHeight = 64.0;
const double _kHumpRise = 22.0; // visible rail rise above the capsule top
const double _kRailOverlap = 5.0; // rail bottom tucked behind the capsule
const double _kRailWidthFactor = 1.4; // rail width = factor * columnWidth
const double _kCapsuleRadius = 32.0;

/// Single source of truth for the bar surface colour — shared by the capsule
/// and the rail tint so the white-on-white merge is exact.
const Color _kSurfaceColor = Colors.white;

// ── TanderBottomNavBar ──────────────────────────────────────────────────────

/// Phone bottom dock: a white capsule + a 5-column segmented layout + a single
/// "rail" indicator that slides to the active column. The rail sits *behind*
/// the capsule, overlapping its top edge by [_kRailOverlap] px so the two white
/// shapes merge into one surface with a traveling hump.
///
/// Phase 1: placeholder boxes stand in for the real icons.
///
/// This is the provider-wiring layer only: it resolves the active tab, badge
/// counts, and reduced-motion, then delegates all layout to [BottomNavBarView]
/// (which is provider-free and therefore directly widget-testable).
class TanderBottomNavBar extends ConsumerWidget {
  const TanderBottomNavBar({super.key});

  static int _badgeForTab(String id, NavBadgeCounts counts) {
    if (id == 'messages') return counts.unreadMessageCount;
    if (id == 'connections') return counts.pendingConnectionCount;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final activeIndex = activeIndexForLocation(location, [
      for (final t in navTabs) t.route,
    ]);
    final badgeCounts = ref.watch(navBadgeProvider);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return BottomNavBarView(
      activeIndex: activeIndex,
      reduceMotion: reduceMotion,
      badgeFor: (id) => _badgeForTab(id, badgeCounts),
      onTap: (index) => context.go(navTabs[index].route),
    );
  }
}

/// Pure presentational bottom dock — no providers, no router. Renders the
/// capsule, the sliding rail, and the 5 placeholder columns from plain inputs.
class BottomNavBarView extends StatelessWidget {
  const BottomNavBarView({
    required this.activeIndex,
    required this.reduceMotion,
    required this.badgeFor,
    required this.onTap,
    super.key,
  });

  final int activeIndex;
  final bool reduceMotion;
  final int Function(String id) badgeFor;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = math.max(MediaQuery.viewPaddingOf(context).bottom, 8.0);

    const totalHeight = _kCapsuleHeight + _kHumpRise;
    const railHeight = _kHumpRise + _kRailOverlap;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final railWidth = (barWidth / navTabs.length) * _kRailWidthFactor;

          return SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Rail — BEHIND the capsule. It is itself an
                //    AnimatedPositioned (top: 0), so it is a direct Stack child.
                NavRailIndicator(
                  activeIndex: activeIndex,
                  columnCount: navTabs.length,
                  barWidth: barWidth,
                  railWidth: railWidth,
                  railHeight: railHeight,
                  reduceMotion: reduceMotion,
                  color: _kSurfaceColor,
                ),
                // 2. White capsule — ON TOP of the rail's 5px overlap seam.
                Positioned(
                  top: _kHumpRise,
                  left: 0,
                  right: 0,
                  height: _kCapsuleHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _kSurfaceColor,
                      borderRadius: BorderRadius.circular(_kCapsuleRadius),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x25000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // 3. Columns (icons + labels) — IN FRONT of everything.
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var i = 0; i < navTabs.length; i++)
                        Expanded(
                          child: _NavCell(
                            descriptor: navTabs[i],
                            isActive: i == activeIndex,
                            badge: badgeFor(navTabs[i].id),
                            humpRise: _kHumpRise,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Single column ───────────────────────────────────────────────────────────

/// One column. Phase 1: a placeholder box sized like the real icons
/// (idle shorter, clicked taller) so Task 7 tunes against realistic
/// dimensions. Phase 2 swaps the box for the idle/clicked `Image.asset`.
class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.descriptor,
    required this.isActive,
    required this.badge,
    required this.humpRise,
    required this.onTap,
  });

  final NavTabDescriptor descriptor;
  final bool isActive;
  final int badge;
  final double humpRise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Realistic placeholder proportions (idle 118 / clicked 163 tall source).
    final accent = _accentFor(descriptor.id);
    final boxW = isActive ? 38.0 : 30.0;
    final boxH = isActive ? 44.0 : 32.0;
    final bottomGap = MediaQuery.viewPaddingOf(context).bottom > 0 ? 2.0 : 6.0;

    return Semantics(
      key: ValueKey('nav-cell-${descriptor.id}'),
      label: badge > 0 ? '${descriptor.label}, $badge unread' : descriptor.label,
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58, minWidth: 58),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Active cell lifts up into the hump.
              Transform.translate(
                offset: Offset(0, isActive ? -humpRise * 0.5 : 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: boxW,
                      height: boxH,
                      decoration: BoxDecoration(
                        color: isActive
                            ? accent
                            : accent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(isActive ? 14 : 10),
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
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive
                      ? accent
                      : const Color(0xFF6B5B4F),
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: bottomGap),
            ],
          ),
        ),
      ),
    );
  }
}
