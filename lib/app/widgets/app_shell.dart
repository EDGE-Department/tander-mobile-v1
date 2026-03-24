import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/top_nav_bar.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_listener.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';
import 'package:tander_flutter_v3/features/calls/presentation/widgets/incoming_call_overlay.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Root scaffold for the authenticated app matching the web's layout:
/// - **Phone** (width < 1024): bottom dock nav bar
/// - **Tablet/Desktop** (width >= 1024): top header nav bar
///
/// Matches web's app-shell.tsx: desktop = top header, mobile = bottom dock.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _hasNavigatedToCall = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(callListenerProvider);

    // Auto-navigate to call screen when incoming call transitions to connecting
    ref.listen<CallState>(callNotifierProvider, (previous, next) {
      if (previous == null) return;
      final wasRinging = previous.isIncomingRinging;
      final isNowConnecting = next.status is CallConnecting || next.status is CallConnected;
      final isIncoming = next.callInfo?.direction == CallDirection.incoming;
      final roomName = next.callInfo?.roomName;

      if (wasRinging && isNowConnecting && isIncoming && roomName != null && !_hasNavigatedToCall) {
        _hasNavigatedToCall = true;
        context.push(AppRoutes.call(roomName));
      }

      // Reset flag when call ends
      if (next.status is CallIdle || next.status is CallEnded) {
        _hasNavigatedToCall = false;
      }
    });

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
                Expanded(child: widget.child),
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
          widget.child,
          if (showOverlay)
            const Positioned.fill(child: IncomingCallOverlay()),
        ],
      ),
      bottomNavigationBar: showOverlay ? null : const TanderBottomNavBar(),
    );
  }
}
