import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/app/router/app_router.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_theme.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_state.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_incoming_call_overlay.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_incoming_call_state.dart';

/// Root application widget.
///
/// Wires [AppTheme.light] and the GoRouter from [appRouterProvider] into a
/// [MaterialApp.router]. Auth-driven navigation is handled entirely by the
/// router's redirect callback — this widget has no routing logic of its own.
final class TanderApp extends ConsumerWidget {
  const TanderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Phase 5 — touch the v2 CallKit listener provider so it auto-starts.
    // The listener subscribes to `flutter_callkit_incoming` events and
    // routes accept/decline to /api/v2/calls/{id}/{accept,decline}-action.
    // Reading is idempotent; the provider's auto-start guards against
    // duplicate subscriptions.
    ref.watch(v2CallkitListenerProvider);
    // Eagerly create the active-call notifier so it subscribes to Twilio
    // events before any call connects — a late subscription would miss the
    // roomConnected/participantConnected events on a broadcast stream.
    ref.watch(v2ActiveCallProvider);

    // Phase 5 — drive WPS lifecycle from auth state.
    // Connect on authenticated, disconnect on unauthenticated. App-lifecycle
    // (foreground/background) is handled inside WpsClient via
    // WidgetsBindingObserver. The provider's idempotency guard makes
    // multiple emits safe. Initial-state check below handles the bootstrap-
    // restored-session case where the listener wouldn't fire.
    final initialAuth = ref.read(authNotifierProvider);
    if (initialAuth is AuthAuthenticated) {
      ref.read(wpsClientProvider).connect();
      // Cold-start: if the app was launched by tapping Accept on a CallKit
      // notification while killed, the session is ready now — consume the
      // native flag and run the v2 accept + connect.
      unawaited(
        ref.read(v2CallkitListenerProvider).consumeColdStartFromNative(),
      );
    }
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final wps = ref.read(wpsClientProvider);
      if (next is AuthAuthenticated) {
        wps.connect();
        unawaited(
          ref.read(v2CallkitListenerProvider).consumeColdStartFromNative(),
        );
      } else if (next is AuthUnauthenticated || next is AuthError) {
        wps.disconnect();
      }
    });

    // Eagerly create the incoming-call notifier so it subscribes to WPS
    // before any CALL_RINGING can arrive. Without this, the notifier
    // only spins up the first time a widget reads it — losing events.
    ref.watch(v2IncomingCallProvider);

    return MaterialApp.router(
      title: 'Tander',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Wrap every navigated screen in the incoming-call overlay host so
      // a v2 ring can paint over any route the user is currently on.
      builder: (context, child) {
        // Respect the OS font-size accessibility setting (important for our
        // 60+ audience) but clamp to 1.3x so fixed chrome stays usable. 1.3x
        // is the threshold our layouts are tuned to adapt to.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: V2IncomingCallOverlayHost(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
