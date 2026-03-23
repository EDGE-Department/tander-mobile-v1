import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_parts.dart';
import 'package:tander_flutter_v3/app/widgets/nav_badge_provider.dart';
import 'package:tander_flutter_v3/app/widgets/side_nav_rail.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_listener.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/widgets/incoming_call_overlay.dart';

/// Root scaffold for the authenticated app. Selects between:
/// - **Phone** (shortestSide <= 600): Scaffold + bottom dock nav
/// - **Tablet** (shortestSide > 600): Row with side navigation rail + content
///
/// Mounts the global call listener and incoming call overlay.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  /// The routed page injected by GoRouter's ShellRoute.builder.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mount the global call listener — stays active for the entire auth session.
    ref.watch(callListenerProvider);

    // Watch call state to show/hide the incoming call overlay.
    final callState = ref.watch(callNotifierProvider);
    final bool showOverlay = callState.isIncomingRinging;

    final double shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final bool isTablet = shortestSide > 600;

    return isTablet
        ? _TabletShell(showOverlay: showOverlay, child: child)
        : _PhoneShell(showOverlay: showOverlay, child: child);
  }
}

// ── Phone layout ────────────────────────────────────────────────────────────

/// Phone: Scaffold with the branded bottom dock nav bar.
class _PhoneShell extends StatelessWidget {
  const _PhoneShell({
    required this.showOverlay,
    required this.child,
  });

  final bool showOverlay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          if (showOverlay)
            const Positioned.fill(child: IncomingCallOverlay()),
        ],
      ),
      bottomNavigationBar: showOverlay ? null : const TanderBottomNavBar(),
    );
  }
}

// ── Tablet layout ───────────────────────────────────────────────────────────

/// Tablet: Row with a glass-morphism side navigation rail on the left.
class _TabletShell extends ConsumerStatefulWidget {
  const _TabletShell({
    required this.showOverlay,
    required this.child,
  });

  final bool showOverlay;
  final Widget child;

  @override
  ConsumerState<_TabletShell> createState() => _TabletShellState();
}

class _TabletShellState extends ConsumerState<_TabletShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tandyPulseController;
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
  }

  @override
  void dispose() {
    _tandyPulseController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final int activeIndex = _resolveActiveIndex(location);
    final EdgeInsets viewPadding = MediaQuery.viewPaddingOf(context);
    final NavBadgeCounts badgeCounts = ref.watch(navBadgeProvider);

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SideNavRail(
                activeIndex: activeIndex,
                badgeCounts: badgeCounts,
                tandyPulseAnimation: _tandyPulseAnimation,
                topPadding: viewPadding.top,
                bottomPadding: viewPadding.bottom,
                onTabTapped: (index) =>
                    context.go(navTabs[index].route),
              ),
              Expanded(child: widget.child),
            ],
          ),
          if (widget.showOverlay)
            const Positioned.fill(child: IncomingCallOverlay()),
        ],
      ),
    );
  }
}
