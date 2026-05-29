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
  static const String uploadAdditionalPhotos = '/user/upload-additional-photos';

  static String deletePhotoByIndex(int photoIndex) =>
      '/user/delete-photo?photoIndex=$photoIndex';

  static const String deleteProfilePhoto = '/user/delete-profile-photo';
  static const String reorderPhotos = '/user/reorder-photos';
  static const String changePassword = '/user/change-password';
  static const String requestDataExport = '/privacy/export';

  // ── Account deletion (privacy, 30-day grace window) ──────────────────
  static const String requestAccountDeletion = '/privacy/account-deletion';
  static const String cancelAccountDeletion =
      '/privacy/account-deletion/cancel';
  static const String accountDeletionStatus = '/privacy/account-deletion';

  // ── Settings ─────────────────────────────────────────────────────────
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String securitySettings = '/settings/security';
  static const String discoverySettings = '/settings/discovery';
  static const String userSettings = '/me/settings';

  // ── Discovery ────────────────────────────────────────────────────────
  static const String discoveryProfiles = '/api/discovery/profiles';

  static String discoveryProfile(String userId) =>
      '/api/discovery/profile/$userId';

  // ── Connections (backend calls them "matches") ───────────────────────
  static const String matchesReceived = '/api/matches/received';
  static const String matchesSent = '/api/matches/sent';
  static const String matchesConnected = '/api/matches/connected';

  static String matchAccept(String matchId) => '/api/matches/$matchId/accept';

  static String matchDecline(String matchId) => '/api/matches/$matchId/decline';

  static String matchCancel(String matchId) => '/api/matches/$matchId/cancel';

  static String matchRemove(String matchId) => '/api/matches/$matchId';

  static const String swipe = '/api/matches/swipe';

  static const String connectionsBlocked = '/api/matches/blocked';

  static String connectionBlock(String connectionId) =>
      '/api/matches/$connectionId/block';

  static String connectionUnmatch(String connectionId) =>
      '/api/matches/$connectionId/unmatch';

  // ── Messages ─────────────────────────────────────────────────────────
  static const String conversations = '/chat/conversations';

  static String conversationMessages(String conversationId) =>
      '/chat/conversations/$conversationId/messages';

  static const String sendMessage = '/chat/messages';

  static String markRead(String conversationId) =>
      '/chat/conversations/$conversationId/read';

  static String muteConversation(String conversationId) =>
      '/chat/conversations/$conversationId/mute';

  static String unmuteConversation(String conversationId) =>
      '/chat/conversations/$conversationId/unmute';

  static String startConversation(String odherUserId) =>
      '/chat/users/$odherUserId/start-conversation';

  static const String sendImageMessage = '/chat/messages/image';
  static const String sendVoiceMessage = '/chat/messages/voice';

  // ── Tandy (AI) ──────────────────────────────────────────────────────
  static const String tandyConversation = '/tandy/conversation';
  static const String tandyGreeting = '/tandy/greeting';
  static const String tandySend = '/tandy/send';
  static const String tandyLanguage = '/tandy/language';

  static String tandyCardExpanded(String messageId) =>
      '/tandy/messages/$messageId/card-expanded';

  static String tandyMessageRating(String messageId) =>
      '/tandy/messages/$messageId/rating';

  static String tandySponsorImpressionClick(String impressionId) =>
      '/tandy/sponsor-impressions/$impressionId/click';

  // ── Calls (legacy v1, raw WebRTC P2P + STOMP) ────────────────────────
  static const String createCallRoom = '/api/twilio/video/room';
  static const String iceServers = '/api/twilio/video/ice-servers';
  static const String acceptCall = '/api/twilio/video/accept';
  static const String declineCall = '/api/twilio/video/decline';
  static const String endCall = '/api/twilio/video/end';
  static const String cancelCall = '/api/twilio/video/cancel';
  static const String callHistory = '/api/twilio/video/history';
  static const String callConfig = '/api/twilio/video/config';

  // ── Calls v2 (Phase 5 native Twilio Programmable Video + WPS) ────────
  static const String callsV2Start = '/api/v2/calls';
  static const String callsV2Active = '/api/v2/calls/active';
  static String callsV2Accept(String callId) => '/api/v2/calls/$callId/accept';
  static String callsV2Decline(String callId) =>
      '/api/v2/calls/$callId/decline';
  static String callsV2Cancel(String callId) => '/api/v2/calls/$callId/cancel';
  static String callsV2End(String callId) => '/api/v2/calls/$callId/end';
  static String callsV2DismissDevice(String callId) =>
      '/api/v2/calls/$callId/dismiss-device';
  static String callsV2Handoff(String callId) =>
      '/api/v2/calls/$callId/handoff';
  static String callsV2Token(String callId) => '/api/v2/calls/$callId/token';
  static String callsV2AcceptAction(String callId) =>
      '/api/v2/calls/$callId/accept-action';
  static String callsV2DeclineAction(String callId) =>
      '/api/v2/calls/$callId/decline-action';
  static String callsV2DismissAction(String callId) =>
      '/api/v2/calls/$callId/dismiss-action';

  // ── Realtime (Azure Web PubSub negotiate) ────────────────────────────
  static const String realtimeNegotiate = '/api/realtime/negotiate';

  // ── Push notifications ──────────────────────────────────────────────
  static const String registerToken = '/notifications/devices';
  static const String registerVoipToken = '/notifications/devices';
  static const String unregisterToken = '/notifications/devices';
  static const String notificationStatus = '/notifications/status';

  // ── Community ───────────────────────────────────────────────────────
  static const String communityFeed = '/api/community/feed';

  static String communityPost(String postId) => '/api/community/posts/$postId';

  static const String createPost = '/api/community/posts';

  static String postComments(String postId) =>
      '/api/community/posts/$postId/comments';

  static String postReactions(String postId) =>
      '/api/community/posts/$postId/reactions';

  static String commentReplies(String commentId) =>
      '/api/community/comments/$commentId/replies';

  static String deleteComment(String commentId) =>
      '/api/community/comments/$commentId';
}
