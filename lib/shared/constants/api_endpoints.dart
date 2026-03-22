/// All backend API endpoints — single source of truth.
///
/// Fixed paths are `static const String`; parameterised paths are
/// static methods that return `String`.  No trailing slashes.
abstract final class ApiEndpoints {
  // ── Auth ─────────────────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String verifyResetOtp = '/api/auth/verify-reset-otp';
  static const String resetPassword = '/api/auth/reset-password';
  static const String resendVerification = '/api/auth/resend-verification';
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String checkEmail = '/api/auth/check-email';
  static const String checkUsername = '/api/auth/check-username';
  static const String idVerification = '/api/auth/id-verification';

  // ── Profile ──────────────────────────────────────────────────────────
  static const String userMe = '/user/me';

  static String userById(int userId) => '/user/$userId';

  static const String updateProfile = '/user/profile';
  static const String uploadProfilePhoto = '/user/upload-profile-photo';
  static const String uploadAdditionalPhotos =
      '/user/upload-additional-photos';

  static String deletePhoto(String photoUrl) =>
      '/user/delete-photo?photoUrl=$photoUrl';

  static const String deleteProfilePhoto = '/user/delete-profile-photo';
  static const String reorderPhotos = '/user/reorder-photos';
  static const String changePassword = '/user/change-password';
  static const String deleteAccount = '/user/delete-account';
  static const String exportData = '/user/export-data';

  // ── Settings ─────────────────────────────────────────────────────────
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String securitySettings = '/settings/security';
  static const String discoverySettings = '/settings/discovery';

  // ── Discovery ────────────────────────────────────────────────────────
  static const String discoveryProfiles = '/api/discovery/profiles';

  static String discoveryProfile(int userId) =>
      '/api/discovery/profile/$userId';

  // ── Connections (backend calls them "matches") ───────────────────────
  static const String matchesReceived = '/api/matches/received';
  static const String matchesSent = '/api/matches/sent';
  static const String matchesConnected = '/api/matches/connected';

  static String matchAccept(int matchId) => '/api/matches/$matchId/accept';

  static String matchDecline(int matchId) =>
      '/api/matches/$matchId/decline';

  static String matchCancel(int matchId) => '/api/matches/$matchId/cancel';

  static String matchRemove(int matchId) => '/api/matches/$matchId';

  static const String swipe = '/api/matches/swipe';

  // ── Messages ─────────────────────────────────────────────────────────
  static const String conversations = '/chat/conversations';

  static String conversationMessages(int conversationId) =>
      '/chat/conversations/$conversationId/messages';

  static const String sendMessage = '/chat/messages';

  static String markRead(int conversationId) =>
      '/chat/conversations/$conversationId/mark-read';

  static String muteConversation(int conversationId) =>
      '/chat/conversations/$conversationId/mute';

  static String unmuteConversation(int conversationId) =>
      '/chat/conversations/$conversationId/unmute';

  static String startConversation(int userId) =>
      '/chat/users/$userId/start-conversation';

  static const String sendImageMessage = '/chat/messages/image';
  static const String sendVoiceMessage = '/chat/messages/voice';

  // ── Tandy (AI) ──────────────────────────────────────────────────────
  static const String tandyConversation = '/api/tandy/conversation';
  static const String tandyGreeting = '/api/tandy/greeting';
  static const String tandySend = '/api/tandy/send';
  static const String tandyLanguage = '/api/tandy/language';

  static String tandyCardExpanded(int messageId) =>
      '/api/tandy/messages/$messageId/card-expanded';

  // ── Calls ────────────────────────────────────────────────────────────
  static const String createCallRoom = '/api/twilio/video/room';
  static const String iceServers = '/api/twilio/video/ice-servers';
  static const String acceptCall = '/api/twilio/video/accept';
  static const String declineCall = '/api/twilio/video/decline';
  static const String endCall = '/api/twilio/video/end';
  static const String cancelCall = '/api/twilio/video/cancel';
  static const String callHistory = '/api/twilio/video/history';
  static const String callConfig = '/api/twilio/video/config';

  // ── Push notifications ──────────────────────────────────────────────
  static const String registerToken = '/api/notifications/register-token';
  static const String registerVoipToken =
      '/api/notifications/register-voip-token';
  static const String unregisterToken =
      '/api/notifications/unregister-token';
  static const String notificationStatus = '/api/notifications/status';

  // ── Community ───────────────────────────────────────────────────────
  static const String communityFeed = '/api/community/feed';

  static String communityPost(int postId) =>
      '/api/community/posts/$postId';

  static const String createPost = '/api/community/posts';

  static String postComments(int postId) =>
      '/api/community/posts/$postId/comments';

  static String postReactions(int postId) =>
      '/api/community/posts/$postId/reactions';
}
