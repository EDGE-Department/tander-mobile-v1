import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_listener.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/widgets/incoming_call_overlay.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Shell wrapping all authenticated routes that should display the bottom
/// navigation bar.
///
/// GoRouter's [ShellRoute] passes the nested child widget; this widget
/// renders the bottom nav and swaps the body. Each tab maps to one of the
/// five main sections: Discover, Connection, Messages, Tandy, Profile.
///
/// Also mounts:
/// - [callListenerProvider] — global STOMP subscription for incoming calls.
/// - [IncomingCallOverlay] — full-screen overlay when an incoming call rings.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mount the global call listener — stays active for the entire auth session.
    ref.watch(callListenerProvider);

    // Watch call state to show/hide the incoming call overlay.
    final callState = ref.watch(callNotifierProvider);
    final showOverlay = callState.isIncomingRinging;

    return Scaffold(
      body: Stack(
        children: [
          child,

          // Incoming call overlay — shown above everything
          if (showOverlay)
            const Positioned.fill(child: IncomingCallOverlay()),
        ],
      ),
      bottomNavigationBar: showOverlay
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex(context),
              onTap: (index) => _onTap(context, index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFE67E22),
              unselectedItemColor: const Color(0xFF9CA3AF),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Discover',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.favorite),
                  label: 'Connection',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.smart_toy_outlined),
                  activeIcon: Icon(Icons.smart_toy),
                  label: 'Tandy',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith(AppRoutes.discover)) return 0;
    if (location.startsWith(AppRoutes.connection)) return 1;
    if (location.startsWith(AppRoutes.messages)) return 2;
    if (location.startsWith(AppRoutes.tandy)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;

    return 0;
  }

  void _onTap(BuildContext context, int index) {
    final destination = switch (index) {
      0 => AppRoutes.discover,
      1 => AppRoutes.connection,
      2 => AppRoutes.messages,
      3 => AppRoutes.tandy,
      4 => AppRoutes.profile,
      _ => AppRoutes.discover,
    };

    context.go(destination);
  }
}
