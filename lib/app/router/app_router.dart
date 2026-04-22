import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/app/router/router_listenable.dart';
import 'package:tander_flutter_v3/app/screens/not_found_screen.dart';
import 'package:tander_flutter_v3/app/widgets/app_shell.dart';
import 'package:tander_flutter_v3/features/calls/presentation/screens/call_screen.dart';
import 'package:tander_flutter_v3/features/community/presentation/screens/community_post_screen.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/screens/tandy_screen.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/screens/tandy_chat_screen.dart';
import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/login_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/id_scanner_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/ready_to_verify_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/notification_permission_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/photo_setup_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/connection/presentation/screens/connection_screen.dart';
import 'package:tander_flutter_v3/features/discover/presentation/screens/discover_profile_screen.dart';
import 'package:tander_flutter_v3/features/discover/presentation/screens/discover_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/screens/call_history_screen.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/screens/message_thread_screen.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/screens/messages_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_photos_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_discovery_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_notifications_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_privacy_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/settings_security_screen.dart';
import 'package:tander_flutter_v3/features/splash/presentation/screens/splash_screen.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ---------------------------------------------------------------------------
// Route groups -- used by the redirect guard to classify locations
// ---------------------------------------------------------------------------

const _publicRoutes = <String>{
  AppRoutes.login,
  AppRoutes.signUp,
  AppRoutes.readyToVerify,
  AppRoutes.idScanner,
  AppRoutes.rateLimit,
  AppRoutes.duplicateId,
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
    // Still loading -- stay where you are if on splash or a public route
    AuthInitial() || AuthLoading() =>
      (isOnSplash || isOnPublicRoute) ? null : AppRoutes.splash,

    // Not authenticated -- go to login (unless already on public route)
    AuthUnauthenticated() || AuthError() =>
      isOnPublicRoute ? null : AppRoutes.login,

    // Onboarding incomplete -- route to the correct step
    AuthOnboarding(:final phase) =>
      _redirectForOnboarding(phase, matchedLocation, isOnOnboardingRoute),

    // Authenticated but on public/onboarding route -- go to discover
    AuthAuthenticated() =>
      (isOnPublicRoute || isOnOnboardingRoute || isOnSplash)
          ? AppRoutes.discover
          : null,
  };
}

String? _redirectForOnboarding(
  RegistrationPhase phase,
  String matchedLocation,
  bool isOnOnboardingRoute,
) {
  final targetRoute = _onboardingRouteForPhase(phase);
  if (targetRoute == AppRoutes.home) return AppRoutes.home;
  return isOnOnboardingRoute ? null : targetRoute;
}

// ---------------------------------------------------------------------------
// Onboarding phase -> route mapping
// ---------------------------------------------------------------------------

String _onboardingRouteForPhase(RegistrationPhase phase) => switch (phase) {
      RegistrationPhase.pendingEmailVerification =>
        AppRoutes.profileSetup,
      RegistrationPhase.pendingProfileSetup => AppRoutes.profileSetup,
      RegistrationPhase.pendingPhotoSetup => AppRoutes.photoSetup,
      RegistrationPhase.pendingIdVerification =>
        AppRoutes.profileSetup, // no separate ID screen yet
      RegistrationPhase.pendingNotificationPermission =>
        AppRoutes.home,
      RegistrationPhase.complete => AppRoutes.home,
    };

// ---------------------------------------------------------------------------
// Route tree
// ---------------------------------------------------------------------------

final _routes = <RouteBase>[
  // -- Splash ---------------------------------------------------------------
  GoRoute(
    path: AppRoutes.splash,
    builder: (_, _) => const SplashScreen(),
  ),

  // -- Public auth routes ---------------------------------------------------
  GoRoute(
    path: AppRoutes.login,
    builder: (_, _) => const LoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.signUp,
    builder: (_, _) => const SignUpScreen(),
  ),
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

  // -- Home redirect -- `/` lands on the default tab ------------------------
  GoRoute(
    path: AppRoutes.home,
    redirect: (_, _) => AppRoutes.discover,
  ),

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
              conversationId:
                  state.pathParameters['conversationId'] ?? '',
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
          GoRoute(
            path: 'chat',
            builder: (_, _) => const TandyChatScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (_, _) => const ProfileEditScreen(),
          ),
          GoRoute(
            path: 'photos',
            builder: (_, _) => const ProfilePhotosScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'settings/notifications',
            builder: (_, _) => const SettingsNotificationsScreen(),
          ),
          GoRoute(
            path: 'settings/privacy',
            builder: (_, _) => const SettingsPrivacyScreen(),
          ),
          GoRoute(
            path: 'settings/security',
            builder: (_, _) => const SettingsSecurityScreen(),
          ),
          GoRoute(
            path: 'settings/discovery',
            builder: (_, _) => const SettingsDiscoveryScreen(),
          ),
        ],
      ),
      // -- Full-screen call (inside shell to preserve STOMP connection) ------
      GoRoute(
        path: '/calls/:roomName',
        builder: (_, state) => CallScreen(
          roomName: state.pathParameters['roomName'] ?? '',
        ),
      ),
    ],
  ),

  // -- Deep navigation ------------------------------------------------------
  GoRoute(
    path: '/discover/profile/:userId',
    builder: (_, state) => DiscoverProfileScreen(
      userId: state.pathParameters['userId'] ?? '',
    ),
  ),
  GoRoute(
    path: '/community/:postId',
    builder: (_, state) {
      final postIdParam = state.pathParameters['postId'] ?? '0';
      final postId = int.tryParse(postIdParam) ?? 0;
      return CommunityPostScreen(postId: postId);
    },
  ),
  GoRoute(
    path: '/user/:userId',
    builder: (_, _) => const UserProfileScreen(),
  ),
];
