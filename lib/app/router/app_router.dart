import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/app/router/router_listenable.dart';
import 'package:tander_flutter_v3/app/screens/not_found_screen.dart';
import 'package:tander_flutter_v3/app/widgets/app_shell.dart';
import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/id_scanner_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/login_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/notification_permission_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/photo_setup_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/ready_to_verify_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/welcome_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/calls/presentation/screens/call_screen.dart';
import 'package:tander_flutter_v3/features/calls/v2/debug_v2_call_screen.dart';
import 'package:tander_flutter_v3/features/community/presentation/screens/community_post_screen.dart';
import 'package:tander_flutter_v3/features/connection/presentation/screens/connection_screen.dart';
import 'package:tander_flutter_v3/features/discover/presentation/screens/discover_profile_screen.dart';
import 'package:tander_flutter_v3/features/discover/presentation/screens/discover_screen.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/screens/call_history_screen.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/screens/message_thread_screen.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/screens/messages_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_photos_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_discovery_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_notifications_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_privacy_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:tander_flutter_v3/features/splash/presentation/screens/splash_screen.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/screens/tandy_chat_screen.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/screens/tandy_screen.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ---------------------------------------------------------------------------
// Route groups -- used by the redirect guard to classify locations
// ---------------------------------------------------------------------------

const _publicRoutes = <String>{
  AppRoutes.login,
  AppRoutes.signUp,
  AppRoutes.readyToVerify,
  AppRoutes.idScanner,
  AppRoutes.forgotPassword,
  AppRoutes.otpVerification,
  AppRoutes.resetPassword,
  AppRoutes.emailVerification,
};

const _onboardingRoutes = <String>{
  AppRoutes.emailVerification,
  AppRoutes.profileSetup,
  AppRoutes.photoSetup,
  AppRoutes.notificationPermission,
};

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Application-wide [GoRouter] with auth + onboarding redirect guards.
///
/// The router re-evaluates its redirect whenever [authNotifierProvider]
/// emits a new state, thanks to [RouterListenable].
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerListenable = RouterListenable(ref);

  ref.onDispose(routerListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerListenable,
    redirect: (_, routerState) {
      final authState = ref.read(authNotifierProvider);
      return _redirect(authState, routerState.matchedLocation);
    },
    errorBuilder: (_, _) => const NotFoundScreen(),
    routes: _routes,
  );
});

// ---------------------------------------------------------------------------
// Redirect logic
// ---------------------------------------------------------------------------

String? _redirect(AuthState authState, String matchedLocation) {
  final isOnSplash = matchedLocation == AppRoutes.splash;
  final isOnPublicRoute = _publicRoutes.contains(matchedLocation);
  final isOnOnboardingRoute = _onboardingRoutes.contains(matchedLocation);

  return switch (authState) {
    // Still loading -- stay where you are if on splash or a public route.
    // AuthError is folded in here, NOT treated as a logout. It arises from:
    // (a) sign-in/register failures (e.g. bad credentials), which happen on
    // public auth routes, so this arm returns null and the screen renders its
    // inline error; and (b) a transient bootstrap / refresh-sync failure
    // (network/5xx), which must NOT force-logout a valid session. On a
    // protected/onboarding route this routes to splash, which re-bootstraps and
    // self-recovers: a transient blip routes onward, while a genuinely
    // expired/revoked session — whose tokens the refresh interceptor has already
    // wiped — finds no tokens on re-bootstrap and resolves to AuthUnauthenticated
    // -> login. So the fold stays authz-safe even though a revoked session
    // currently transitions via AuthError rather than AuthUnauthenticated
    // directly (onSessionExpiredProvider is still an unwired placeholder).
    AuthInitial() ||
    AuthLoading() ||
    AuthError() => (isOnSplash || isOnPublicRoute) ? null : AppRoutes.splash,

    // Not authenticated -- go to login (unless already on public route)
    AuthUnauthenticated() => isOnPublicRoute ? null : AppRoutes.login,

    // Onboarding incomplete -- route to the correct step
    AuthOnboarding(:final phase) => _redirectForOnboarding(
      phase,
      isOnSplash,
      isOnPublicRoute,
      isOnOnboardingRoute,
    ),

    // Authenticated but on public/onboarding route -- go to discover
    AuthAuthenticated() =>
      (isOnPublicRoute || isOnOnboardingRoute || isOnSplash)
          ? AppRoutes.discover
          : null,
  };
}

/// Test-only access to the pure redirect-decision function. The guard is
/// otherwise private and driven by GoRouter; exposing it lets the
/// loop-prevention + AuthError-not-logout semantics be unit-tested directly.
@visibleForTesting
String? redirectForTest(AuthState authState, String matchedLocation) =>
    _redirect(authState, matchedLocation);

String? _redirectForOnboarding(
  RegistrationPhase phase,
  bool isOnSplash,
  bool isOnPublicRoute,
  bool isOnOnboardingRoute,
) {
  final targetRoute = _onboardingRouteForPhase(phase);
  if (targetRoute == AppRoutes.home) {
    // Home-mapped phases (pendingIdVerification / pendingNotificationPermission)
    // let the user into the main app. Only pull them in from splash / a public
    // auth route; otherwise leave them where they are. Returning AppRoutes.home
    // here would loop, since `/` redirects to `/discover` while the auth state
    // stays AuthOnboarding (re-triggering this redirect) until GoRouter bails to
    // the 404 screen — so land on the real tab and return null once settled.
    return (isOnSplash || isOnPublicRoute) ? AppRoutes.discover : null;
  }
  return isOnOnboardingRoute ? null : targetRoute;
}

// ---------------------------------------------------------------------------
// Onboarding phase -> route mapping
// ---------------------------------------------------------------------------

String _onboardingRouteForPhase(RegistrationPhase phase) => switch (phase) {
  RegistrationPhase.pendingProfileSetup => AppRoutes.profileSetup,
  RegistrationPhase.pendingPhotoSetup => AppRoutes.photoSetup,
  // pendingIdVerification is never emitted mid-onboarding in the current
  // flow (ID is verified pre-registration), so route it to home as a safe
  // default rather than back to profileSetup which would cause a loop.
  RegistrationPhase.pendingIdVerification => AppRoutes.home,
  RegistrationPhase.pendingNotificationPermission => AppRoutes.home,
  RegistrationPhase.complete => AppRoutes.home,
};

// ---------------------------------------------------------------------------
// Route tree
// ---------------------------------------------------------------------------

final _routes = <RouteBase>[
  // -- Splash ---------------------------------------------------------------
  GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),

  // -- Public auth routes ---------------------------------------------------
  GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
  GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpScreen()),
  GoRoute(
    path: AppRoutes.readyToVerify,
    builder: (_, _) => const ReadyToVerifyScreen(),
  ),
  GoRoute(
    path: AppRoutes.idScanner,
    builder: (_, _) => const IdScannerScreen(),
  ),
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (_, _) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: AppRoutes.otpVerification,
    builder: (_, _) => const OtpVerificationScreen(),
  ),
  GoRoute(
    path: AppRoutes.resetPassword,
    builder: (_, _) => const ResetPasswordScreen(),
  ),
  GoRoute(
    path: AppRoutes.emailVerification,
    builder: (_, _) => const EmailVerificationScreen(),
  ),

  // -- Onboarding routes (auth required, incomplete profile) ----------------
  GoRoute(
    path: AppRoutes.profileSetup,
    builder: (_, _) => const ProfileSetupScreen(),
  ),
  GoRoute(
    path: AppRoutes.photoSetup,
    builder: (_, _) => const PhotoSetupScreen(),
  ),
  GoRoute(
    path: AppRoutes.notificationPermission,
    builder: (_, _) => const NotificationPermissionScreen(),
  ),

  // -- Post-onboarding celebration (auth-required, non-gating) -------------
  // Intentionally NOT in `_onboardingRoutes` — shown once via explicit
  // `context.go(AppRoutes.welcome)` from the notification-permission screen,
  // gated by a `has_seen_welcome_screen` flag in LocalStorage.
  GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeScreen()),

  // -- Home redirect -- `/` lands on the default tab ------------------------
  GoRoute(path: AppRoutes.home, redirect: (_, _) => AppRoutes.discover),

  // -- App shell with bottom nav (authenticated + onboarding complete) ------
  ShellRoute(
    builder: (_, _, child) => AppShell(child: child),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.discover,
        builder: (_, _) => const DiscoverScreen(),
      ),
      GoRoute(
        path: AppRoutes.connection,
        builder: (_, _) => const ConnectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (_, _) => const MessagesScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':conversationId',
            builder: (_, state) => MessageThreadScreen(
              conversationId: state.pathParameters['conversationId'] ?? '',
            ),
          ),
          GoRoute(
            path: 'call-history',
            builder: (_, _) => const CallHistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.tandy,
        builder: (_, _) => const TandyScreen(),
        routes: <RouteBase>[
          GoRoute(path: 'chat', builder: (_, _) => const TandyChatScreen()),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
        routes: <RouteBase>[
          GoRoute(path: 'edit', builder: (_, _) => const ProfileEditScreen()),
          GoRoute(
            path: 'photos',
            builder: (_, _) => const ProfilePhotosScreen(),
          ),
          GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(
            path: 'settings/notifications',
            builder: (_, _) => const SettingsNotificationsScreen(),
          ),
          GoRoute(
            path: 'settings/privacy',
            builder: (_, _) => const SettingsPrivacyScreen(),
          ),
          GoRoute(
            path: 'settings/discovery',
            builder: (_, _) => const SettingsDiscoveryScreen(),
          ),
        ],
      ),
    ],
  ),

  // -- Full-screen call (top-level for reliable navigation) -----------------
  GoRoute(
    path: '/call',
    name: 'call',
    builder: (_, state) =>
        CallScreen(roomName: state.uri.queryParameters['room'] ?? ''),
  ),

  // -- Phase 5 v2 debug call screen (dev-only; not registered in release) --
  if (kDebugMode)
    GoRoute(
      path: AppRoutes.debugV2Call,
      builder: (_, _) => const DebugV2CallScreen(),
    ),

  // -- Deep navigation ------------------------------------------------------
  GoRoute(
    path: '/discover/profile/:userId',
    builder: (_, state) =>
        DiscoverProfileScreen(userId: state.pathParameters['userId'] ?? ''),
  ),
  GoRoute(
    path: '/community/:postId',
    builder: (_, state) {
      final postId = state.pathParameters['postId'] ?? '';
      return CommunityPostScreen(postId: postId);
    },
  ),
  GoRoute(path: '/user/:userId', builder: (_, _) => const UserProfileScreen()),
];
