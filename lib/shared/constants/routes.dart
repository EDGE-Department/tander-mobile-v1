/// All route path constants for GoRouter — single source of truth.
///
/// Matches tander-web routing (excluding the landing page, which is
/// web-only).  Fixed paths are `static const String`; parameterised
/// paths are static methods that return `String`.
abstract final class AppRoutes {
  // ── Splash ──────────────────────────────────────────────────────────
  static const String splash = '/splash';

  // ── Auth (public) ───────────────────────────────────────────────────
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';
  static const String emailVerification = '/email-verification';
  static const String signUp = '/sign-up';
  static const String readyToVerify = '/ready-to-verify';
  static const String idScanner = '/id-scanner';

  // ── Onboarding (auth required, incomplete profile) ──────────────────
  static const String profileSetup = '/profile-setup';
  static const String photoSetup = '/photo-setup';
  static const String notificationPermission = '/notification-permission';

  // ── Post-onboarding celebration (auth required; non-gating) ─────────
  static const String welcome = '/welcome';

  // ── App shell (authenticated, profile complete) ─────────────────────
  static const String home = '/';
  static const String discover = '/discover';
  static const String connection = '/connection';
  static const String messages = '/messages';
  static const String tandy = '/tandy';
  static const String profile = '/profile';

  // ── Deep navigation ─────────────────────────────────────────────────
  static String messageThread(String conversationId) =>
      '/messages/$conversationId';

  static const String callHistory = '/messages/call-history';

  static String call(String roomName) => '/call?room=$roomName';

  /// Phase 5 debug-only test screen for v2 calls. Not user-facing —
  /// accessed via a hidden gesture on the profile screen.
  static const String debugV2Call = '/debug/v2-call';

  static String discoverProfile(String userId) => '/discover/profile/$userId';

  static const String discoverFilters = '/discover/filters';

  static String communityPost(String postId) => '/community/$postId';

  static const String tandyChat = '/tandy/chat';

  static const String profileEdit = '/profile/edit';
  static const String profilePhotos = '/profile/photos';
  static const String profileSettings = '/profile/settings';
  static const String profileSettingsNotifications =
      '/profile/settings/notifications';
  static const String profileSettingsPrivacy = '/profile/settings/privacy';
  static const String profileSettingsDiscovery = '/profile/settings/discovery';

  static String userProfile(String userId) => '/user/$userId';
}
