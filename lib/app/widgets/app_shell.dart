import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/top_nav_bar.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_listener.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/widgets/incoming_call_overlay.dart';

/// Root scaffold for the authenticated app matching the web's layout:
/// - **Phone** (width < 1024): bottom dock nav bar
/// - **Tablet/Desktop** (width >= 1024): top header nav bar
///
/// Matches web's app-shell.tsx: desktop = top header, mobile = bottom dock.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(callListenerProvider);

    final callState = ref.watch(callNotifierProvider);
    final bool showOverlay = callState.isIncomingRinging;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool useTopNav = screenWidth >= 1024;

    if (useTopNav) {
      // Tablet/Desktop: top header bar (matches web's lg: layout)
      return Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                const TanderTopNavBar(),
                Expanded(child: child),
              ],
            ),
            if (showOverlay)
              const Positioned.fill(child: IncomingCallOverlay()),
          ],
        ),
      );
    }

    // Phone: bottom dock nav bar (matches web's MobileBottomDock)
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
