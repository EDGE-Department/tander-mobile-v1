import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/services/call_push_bridge.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ---------------------------------------------------------------------------
// Notification type constants — must match backend payload `type` field
// ---------------------------------------------------------------------------

const String _typeIncomingCall = 'incoming_call';
const String _typeMissedCall = 'missed_call';
const String _typeNewMessage = 'new_message';
const String _typeCallCancelled = 'call_cancelled';
const String _typeCommunityComment = 'community_comment';
const String _typeCommunityReply = 'community_reply';
const String _typeNewMatch = 'new_match';
const String _typeMatchAccepted = 'match_accepted';

/// Routes incoming push notifications to the correct UI surface.
///
/// Three entry points:
/// 1. **Foreground** — the app is visible; show in-app UI (toast/overlay).
/// 2. **Background tap** — user tapped a system notification; navigate.
/// 3. **Terminated launch** — app cold-started from a notification tap.
///
/// The background message handler ([handleBackgroundMessage]) is a top-level
/// function as required by Firebase.
final class NotificationHandler {
  const NotificationHandler._();

  /// Wires all Firebase Messaging listeners.
  ///
  /// [router] is used for deep-link navigation when the user taps a
  /// notification. [onForegroundCall] is invoked when an `incoming_call`
  /// arrives while the app is in the foreground (Phase 11 will supply the
  /// call overlay trigger). [onCallCancelled] dismisses call UI silently.
  static Future<void> initialize({
    required GoRouter router,
    required void Function(RemoteMessage message) onForegroundCall,
    required void Function(RemoteMessage message) onCallCancelled,
    required void Function(RemoteMessage message) onForegroundToast,
  }) async {
    // Foreground messages — app is visible
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) => _handleForegroundMessage(
        message,
        onForegroundCall: onForegroundCall,
        onCallCancelled: onCallCancelled,
        onForegroundToast: onForegroundToast,
      ),
      onError: _handleStreamError,
    );

    // User tapped a notification while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) => _handleNotificationTap(message, router),
      onError: _handleStreamError,
    );

    // App was terminated and launched by tapping a notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage, router);
    }

    AppLogger.info(
      'Notification handler initialized',
      operation: 'NotificationHandler.initialize',
    );
  }

  // ---------------------------------------------------------------------------
  // Foreground message routing
  // ---------------------------------------------------------------------------

  static void _handleForegroundMessage(
    RemoteMessage message, {
    required void Function(RemoteMessage message) onForegroundCall,
    required void Function(RemoteMessage message) onCallCancelled,
    required void Function(RemoteMessage message) onForegroundToast,
  }) {
    final notificationType = _extractNotificationType(message);

    AppLogger.debug(
      'Foreground notification received',
      operation: 'NotificationHandler._handleForegroundMessage',
      context: {'type': notificationType ?? 'unknown'},
    );

    switch (notificationType) {
      case _typeIncomingCall:
        onForegroundCall(message);

      case _typeNewMessage:
      case _typeMissedCall:
        onForegroundToast(message);

      case _typeCallCancelled:
        onCallCancelled(message);

      case _typeCommunityComment:
      case _typeCommunityReply:
      case _typeNewMatch:
      case _typeMatchAccepted:
        onForegroundToast(message);

      case null:
        AppLogger.warning(
          'Foreground notification missing type field — ignored',
          operation: 'NotificationHandler._handleForegroundMessage',
          context: {'messageId': message.messageId ?? 'none'},
        );

      default:
        AppLogger.warning(
          'Foreground notification with unknown type — ignored',
          operation: 'NotificationHandler._handleForegroundMessage',
          context: {'type': notificationType},
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Notification tap routing (background + terminated launch)
  // ---------------------------------------------------------------------------

  static void _handleNotificationTap(RemoteMessage message, GoRouter router) {
    final notificationType = _extractNotificationType(message);

    AppLogger.info(
      'Notification tapped',
      operation: 'NotificationHandler._handleNotificationTap',
      context: {'type': notificationType ?? 'unknown'},
    );

    switch (notificationType) {
      case _typeNewMessage:
        final conversationId = _extractStringField(message, 'conversationId');
        if (conversationId != null) {
          router.go(AppRoutes.messageThread(conversationId));
        } else {
          AppLogger.warning(
            'new_message tap missing conversationId — navigating to messages',
            operation: 'NotificationHandler._handleNotificationTap',
          );
          router.go(AppRoutes.messages);
        }

      case _typeMissedCall:
        router.go(AppRoutes.callHistory);

      case _typeIncomingCall:
        // Call overlay handles incoming calls — no navigation needed.
        AppLogger.debug(
          'incoming_call tap — call overlay will handle display',
          operation: 'NotificationHandler._handleNotificationTap',
        );

      case _typeCallCancelled:
        // Data-only notification; no user-facing action on tap.
        AppLogger.debug(
          'call_cancelled tap — no navigation action',
          operation: 'NotificationHandler._handleNotificationTap',
        );

      case _typeCommunityComment:
      case _typeCommunityReply:
        router.go(AppRoutes.discover);

      case _typeNewMatch:
      case _typeMatchAccepted:
        router.go(AppRoutes.connection);

      case null:
        AppLogger.warning(
          'Notification tap missing type field — ignored',
          operation: 'NotificationHandler._handleNotificationTap',
          context: {'messageId': message.messageId ?? 'none'},
        );

      default:
        AppLogger.warning(
          'Notification tap with unknown type — ignored',
          operation: 'NotificationHandler._handleNotificationTap',
          context: {'type': notificationType},
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Payload extraction helpers — explicit type checks, no `dynamic` casts
  // ---------------------------------------------------------------------------

  /// Extracts the `type` field from the notification data payload.
  ///
  /// Returns `null` if the field is absent or not a [String].
  static String? _extractNotificationType(RemoteMessage message) {
    final rawType = message.data['type'];
    return rawType is String ? rawType : null;
  }

  /// Extracts a named [String] field from the notification data payload.
  ///
  /// Returns `null` if the field is absent or not a [String].
  static String? _extractStringField(RemoteMessage message, String field) {
    final rawValue = message.data[field];
    return rawValue is String && rawValue.isNotEmpty ? rawValue : null;
  }

  // ---------------------------------------------------------------------------
  // Stream error handler
  // ---------------------------------------------------------------------------

  static void _handleStreamError(Object error, StackTrace stackTrace) {
    AppLogger.error(
      'Firebase messaging stream emitted an error',
      operation: 'NotificationHandler._handleStreamError',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

// ---------------------------------------------------------------------------
// Top-level background message handler (Firebase requirement)
// ---------------------------------------------------------------------------

/// Top-level function for handling background/terminated push notifications.
///
/// Firebase requires this to be a top-level or static function — it runs in
/// its own isolate and cannot access widget state.
///
/// For call-related pushes (`incoming_call`, `call_cancelled`, `call_ended`),
/// routes to [CallPushBridge] which shows/dismisses native CallKit UI.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate.
  // On Android, onBackgroundMessage runs in a separate Dart isolate
  // where Firebase may not yet be initialized.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized — safe to ignore
  }

  final rawType = message.data['type'];
  final notificationType = rawType is String ? rawType : 'unknown';

  debugPrint(
    '[BG] Background message received: type=$notificationType '
    'keys=${message.data.keys.toList()}',
  );

  // Route call-related pushes to CallPushBridge for native UI
  if (notificationType == _typeIncomingCall ||
      notificationType == _typeCallCancelled ||
      notificationType == 'call_ended') {
    final wasHandled = await CallPushBridge.handleBackgroundCallPush(
      message.data,
    );
    debugPrint('[BG] Call push handled=$wasHandled type=$notificationType');
  }
}
