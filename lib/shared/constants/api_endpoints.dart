/// All backend API endpoints — single source of truth.
///
/// Fixed paths are `static const String`; parameterised paths are
/// static methods that return `String`.  No trailing slashes.
abstract final class ApiEndpoints {
  // ── Auth ─────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String resendVerification = '/auth/resend-verification';
  static const String sendOtp = '/api/twilio/otp/send';
  static const String verifyOtp = '/api/twilio/otp/verify';
  static const String sendEmailOtp = '/api/twilio/otp/send-email';
  static const String verifyEmailOtp = '/api/twilio/otp/verify-email';
  static const String checkEmail = '/auth/check-email';
  static const String checkUsername = '/auth/check-username';
  static const String idVerification = '/auth/id-verification';
  static const String verifyIdPreRegister = '/auth/verify-id-preregister';
  static const String verificationConfig = '/auth/verification-config';
  static const String checkPhone = '/auth/check-phone';

  // ── Profile ──────────────────────────────────────────────────────────
  static const String userMe = '/user/me';
  static const String identityData = '/user/identity-data';

  static String userById(int userId) => '/user/$userId';

  static const String updateProfile = '/user/profile';
  static const String uploadProfilePhoto = '/user/upload-profile-photo';
  static const String uploadAdditionalPhotos =
      '/user/upload-additional-photos';

  static String deletePhotoByIndex(int photoIndex) =>
      '/user/delete-photo?photoIndex=$photoIndex';

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

  static String commentReplies(int commentId) =>
      '/api/community/comments/$commentId/replies';
}
