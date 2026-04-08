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
  static const String idScanner = '/id-scanner';
  static const String rateLimit = '/rate-limit';
  static const String duplicateId = '/duplicate-id';

  // ── Onboarding (auth required, incomplete profile) ──────────────────
  static const String profileSetup = '/profile-setup';
  static const String photoSetup = '/photo-setup';
  static const String notificationPermission = '/notification-permission';

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

  static String call(String roomName) => '/calls/$roomName';

  static String discoverProfile(String userId) =>
      '/discover/profile/$userId';

  static const String discoverFilters = '/discover/filters';

  static String communityPost(String postId) => '/community/$postId';

  static const String tandyChat = '/tandy/chat';

  static const String profileEdit = '/profile/edit';
  static const String profilePhotos = '/profile/photos';
  static const String profileSettings = '/profile/settings';
  static const String profileSettingsNotifications =
      '/profile/settings/notifications';
  static const String profileSettingsPrivacy = '/profile/settings/privacy';
  static const String profileSettingsSecurity = '/profile/settings/security';
  static const String profileSettingsDiscovery = '/profile/settings/discovery';

  static String userProfile(String userId) => '/user/$userId';
}
