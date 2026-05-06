import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Notification channel IDs — Android only
// ---------------------------------------------------------------------------

const String _callsChannelId = 'tander_calls';
const String _callsChannelName = 'Calls';
const String _callsChannelDescription =
    'Incoming and missed call notifications';

const String _messagesChannelId = 'tander_messages';
const String _messagesChannelName = 'Messages';
const String _messagesChannelDescription = 'New message notifications';

const String _generalChannelId = 'tander_general';
const String _generalChannelName = 'General';
const String _generalChannelDescription = 'General app notifications';

// ---------------------------------------------------------------------------
// Local storage key for stable device ID
// ---------------------------------------------------------------------------

const String _deviceIdKey = 'tander_device_id';
const String _voipTokenKey = 'tander_voip_push_token';

/// Manages FCM token lifecycle: permission request, token registration,
/// token refresh, and backend synchronisation.
///
/// Android notification channels are created during [initialize] so the OS
/// can categorise notifications by importance level.
final class PushNotificationService {
  PushNotificationService({
    required DioClient dioClient,
    required SharedPreferences sharedPreferences,
  })  : _dioClient = dioClient,
        _sharedPreferences = sharedPreferences;

  final DioClient _dioClient;
  final SharedPreferences _sharedPreferences;

  /// VoIP token event subscription (iOS-only). Held so we can cancel on
  /// unregister/sign-out.
  StreamSubscription<CallEvent?>? _voipEventSub;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Requests notification permission, retrieves the FCM token, registers
  /// it with the backend, and begins listening for token refreshes.
  ///
  /// Safe to call multiple times — Firebase internally deduplicates.
  Future<void> initialize() async {
    await _createAndroidNotificationChannels();
    await _requestPermission();

    // iOS-specific: enable foreground notification display and ensure APNs
    // token is ready before requesting FCM token.
    String? apnsToken;
    if (Platform.isIOS) {
      await _configureIOSForegroundPresentation();
      apnsToken = await _ensureApnsToken();

      if (apnsToken == null) {
        AppLogger.error(
          'APNs token unavailable — FCM token will likely fail on iOS. '
          'Push notifications will not work.',
          operation: 'PushNotificationService.initialize',
        );
      } else {
        AppLogger.info(
          'APNs token ready, proceeding to FCM registration',
          operation: 'PushNotificationService.initialize',
        );
        // Short delay to ensure Firebase SDK has processed the APNs token
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    // Get FCM token with timeout + retry (mirrors legacy app's TokenManager)
    // On iOS, increase retries since APNs→FCM mapping can take time
    final maxAttempts = Platform.isIOS ? 5 : 3;
    String? fcmToken;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        fcmToken = await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 15));
        if (fcmToken != null) {
          AppLogger.info(
            'FCM token obtained on attempt $attempt: ${fcmToken.substring(0, 20)}...',
            operation: 'PushNotificationService.initialize',
          );
          break;
        }
        AppLogger.warning(
          'FCM token null on attempt $attempt/$maxAttempts',
          operation: 'PushNotificationService.initialize',
        );
      } catch (error) {
        AppLogger.warning(
          'FCM token attempt $attempt/$maxAttempts failed: $error',
          operation: 'PushNotificationService.initialize',
        );
      }
      if (attempt < maxAttempts) {
        await Future<void>.delayed(Duration(seconds: 2 * attempt));
      }
    }

    if (fcmToken != null) {
      await _registerToken(fcmToken);
    } else {
      AppLogger.error(
        'FCM token unavailable after $maxAttempts attempts — push notifications disabled. '
        'Platform: ${Platform.isIOS ? "iOS" : "Android"}, APNs token: ${apnsToken != null ? "present" : "missing"}',
        operation: 'PushNotificationService.initialize',
      );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerToken,
      onError: _handleTokenRefreshError,
    );

    // iOS VoIP token (PushKit). Two strategies in parallel — see TokenManager
    // notes in legacy: a one-shot polling pass to catch tokens already
    // delivered to the plugin, plus a persistent event listener so any later
    // PushKit delivery is captured too.
    if (Platform.isIOS) {
      _listenForVoipTokenEvent();
      unawaited(_acquireVoipToken());
    }

    AppLogger.info(
      'Push notification service initialized',
      operation: 'PushNotificationService.initialize',
    );
  }

  /// Unregisters the current FCM token from the backend so the device
  /// stops receiving push notifications (e.g. on sign-out). Also clears the
  /// VoIP token if one was registered.
  Future<void> unregisterToken() async {
    // Stop listening for further VoIP token deliveries.
    await _voipEventSub?.cancel();
    _voipEventSub = null;

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final encoded = Uri.encodeComponent(fcmToken);
        await _dioClient.delete<void>(
          '${ApiEndpoints.unregisterToken}?token=$encoded',
        );
        AppLogger.info(
          'FCM token unregistered from backend',
          operation: 'PushNotificationService.unregisterToken',
        );
      }
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Failed to unregister FCM token',
        operation: 'PushNotificationService.unregisterToken',
        error: error,
        stackTrace: stackTrace,
      );
    }

    // VoIP token is iOS-only and stored locally — also try to deactivate it
    // backend-side so future calls don't ring a stale device.
    final voipToken = _sharedPreferences.getString(_voipTokenKey);
    if (voipToken != null && voipToken.isNotEmpty) {
      try {
        final encoded = Uri.encodeComponent(voipToken);
        await _dioClient.delete<void>(
          '${ApiEndpoints.unregisterToken}?token=$encoded',
        );
        await _sharedPreferences.remove(_voipTokenKey);
        AppLogger.info(
          'VoIP token unregistered from backend',
          operation: 'PushNotificationService.unregisterToken',
        );
      } on Object catch (error) {
        AppLogger.warning(
          'Best-effort VoIP unregister failed: $error',
          operation: 'PushNotificationService.unregisterToken',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    AppLogger.info(
      'Requesting notification permission...',
      operation: 'PushNotificationService._requestPermission',
    );

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info(
        'Notification permission result: ${settings.authorizationStatus.name}',
        operation: 'PushNotificationService._requestPermission',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.warning(
          'User denied notification permission. Push notifications will not work. '
          'User must enable in iOS Settings > Tander > Notifications.',
          operation: 'PushNotificationService._requestPermission',
        );
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        AppLogger.warning(
          'Notification permission still undetermined after request. '
          'This may indicate iOS did not show the permission dialog.',
          operation: 'PushNotificationService._requestPermission',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to request notification permission: $error',
        operation: 'PushNotificationService._requestPermission',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // iOS-specific configuration
  // ---------------------------------------------------------------------------

  /// Tells iOS to show notification banners, badges, and sounds even when the
  /// app is in the foreground. Without this, iOS delivers notifications
  /// silently to the app but does not display them to the user.
  Future<void> _configureIOSForegroundPresentation() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    AppLogger.debug(
      'iOS foreground notification presentation configured',
      operation: 'PushNotificationService._configureIOSForegroundPresentation',
    );
  }

  /// Ensures the APNs token is available before requesting an FCM token.
  ///
  /// On iOS, FCM generates a device token by wrapping the APNs token. If the
  /// APNs token is not yet available (e.g. first launch, network delay), FCM
  /// returns null or an invalid token. This method polls for the APNs token
  /// with a short backoff to ensure FCM registration succeeds.
  Future<String?> _ensureApnsToken() async {
    const maxAttempts = 10;
    const delays = [1, 2, 2, 3, 3, 4, 4, 5, 5, 5];

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          AppLogger.info(
            'APNs token acquired (attempt $attempt): ${apnsToken.substring(0, 20)}...',
            operation: 'PushNotificationService._ensureApnsToken',
          );
          return apnsToken;
        }
        AppLogger.debug(
          'APNs token null on attempt $attempt/$maxAttempts',
          operation: 'PushNotificationService._ensureApnsToken',
        );
      } catch (error) {
        AppLogger.warning(
          'APNs token attempt $attempt/$maxAttempts failed: $error',
          operation: 'PushNotificationService._ensureApnsToken',
        );
      }

      if (attempt < maxAttempts) {
        await Future<void>.delayed(Duration(seconds: delays[attempt - 1]));
      }
    }

    AppLogger.error(
      'APNs token not available after $maxAttempts attempts. '
      'FCM token will likely be invalid. Check: Push Notifications capability in '
      'Xcode, APNs key uploaded to Firebase Console, device not simulator.',
      operation: 'PushNotificationService._ensureApnsToken',
    );
    return null;
  }

  // ---------------------------------------------------------------------------
  // Token registration
  // ---------------------------------------------------------------------------

  Future<void> _registerToken(String fcmToken) async {
    final deviceId = _getOrCreateDeviceId();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    AppLogger.info(
      'Registering FCM token with backend — platform: $platform, '
      'deviceId: $deviceId, token: ${fcmToken.substring(0, 20)}...',
      operation: 'PushNotificationService._registerToken',
    );

    for (var attempt = 1; attempt <= 5; attempt++) {
      try {
        final response = await _dioClient.post<Map<String, Object?>>(
          ApiEndpoints.registerToken,
          data: {
            'token': fcmToken,
            'platform': platform,
            'deviceId': deviceId,
            'tokenType': 'fcm',
          },
        );

        AppLogger.info(
          'FCM token registered with backend successfully (attempt $attempt). '
          'Response: ${response.statusCode}',
          operation: 'PushNotificationService._registerToken',
          context: {'platform': platform, 'deviceId': deviceId},
        );
        return;
      } on Object catch (error) {
        AppLogger.warning(
          'FCM register attempt $attempt/5 failed: $error',
          operation: 'PushNotificationService._registerToken',
          context: {'platform': platform, 'deviceId': deviceId},
        );
        if (attempt < 5) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    AppLogger.error(
      'Failed to register FCM token after 5 attempts — platform: $platform',
      operation: 'PushNotificationService._registerToken',
    );
  }

  // ---------------------------------------------------------------------------
  // VoIP token (iOS only — PushKit / CallKit lock-screen wakes)
  // ---------------------------------------------------------------------------

  /// Polls the plugin for a VoIP token with progressive backoff. PushKit
  /// delivery is asynchronous via the native AppDelegate's
  /// `pushRegistry(didUpdate pushCredentials:)` callback — which may not have
  /// fired yet on first call. ~28s window covers slow startups.
  Future<void> _acquireVoipToken() async {
    const delays = <int>[0, 2, 3, 5, 8, 10];

    for (var attempt = 0; attempt < delays.length; attempt++) {
      if (delays[attempt] > 0) {
        await Future<void>.delayed(Duration(seconds: delays[attempt]));
      }
      try {
        final result = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        final voipToken = result is String ? result : result?.toString();
        if (voipToken != null && voipToken.isNotEmpty && voipToken != 'null') {
          AppLogger.info(
            'VoIP token acquired (attempt ${attempt + 1})',
            operation: 'PushNotificationService._acquireVoipToken',
          );
          await _registerVoipToken(voipToken);
          return;
        }
      } on Object catch (error) {
        AppLogger.warning(
          'VoIP token poll attempt ${attempt + 1}/${delays.length} failed: $error',
          operation: 'PushNotificationService._acquireVoipToken',
        );
      }
    }

    AppLogger.warning(
      'VoIP token still null after ${delays.length} attempts. iOS '
      'lock-screen calls will not wake the app. Check: PushKit entitlements, '
      'provisioning profile, VoIP Services capability in Apple dev portal.',
      operation: 'PushNotificationService._acquireVoipToken',
    );
  }

  /// Subscribes to the plugin's CallEvent stream and registers any VoIP
  /// token PushKit delivers later. Idempotent — registers only when the token
  /// changes.
  void _listenForVoipTokenEvent() {
    _voipEventSub?.cancel();
    _voipEventSub = FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      if (event.event != Event.actionDidUpdateDevicePushTokenVoip) return;

      final body = event.body as Map<dynamic, dynamic>?;
      final voipToken = body?['deviceTokenVoIP']?.toString();
      if (voipToken == null || voipToken.isEmpty) return;

      final stored = _sharedPreferences.getString(_voipTokenKey);
      if (stored == voipToken) return; // unchanged — skip re-register

      AppLogger.info(
        'VoIP token received via plugin event — registering',
        operation: 'PushNotificationService._listenForVoipTokenEvent',
      );
      await _registerVoipToken(voipToken);
    });
  }

  Future<void> _registerVoipToken(String voipToken) async {
    final deviceId = _getOrCreateDeviceId();
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _dioClient.post<Map<String, Object?>>(
          ApiEndpoints.registerToken,
          data: {
            'token': voipToken,
            'platform': 'voip',
            'deviceId': deviceId,
          },
        );
        await _sharedPreferences.setString(_voipTokenKey, voipToken);
        AppLogger.info(
          'VoIP token registered with backend (attempt $attempt)',
          operation: 'PushNotificationService._registerVoipToken',
        );
        return;
      } on Object catch (error) {
        AppLogger.warning(
          'VoIP register attempt $attempt/3 failed: $error',
          operation: 'PushNotificationService._registerVoipToken',
        );
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    AppLogger.error(
      'Failed to register VoIP token after 3 attempts',
      operation: 'PushNotificationService._registerVoipToken',
    );
  }

  // ---------------------------------------------------------------------------
  // Device ID — stable across app restarts, generated once
  // ---------------------------------------------------------------------------

  String _getOrCreateDeviceId() {
    final existingId = _sharedPreferences.getString(_deviceIdKey);
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final newDeviceId = const Uuid().v4();
    _sharedPreferences.setString(_deviceIdKey, newDeviceId);

    AppLogger.debug(
      'Generated new stable device ID',
      operation: 'PushNotificationService._getOrCreateDeviceId',
      context: {'deviceId': newDeviceId},
    );

    return newDeviceId;
  }

  // ---------------------------------------------------------------------------
  // Android notification channels
  // ---------------------------------------------------------------------------

  Future<void> _createAndroidNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final flutterLocalNotifications = FlutterLocalNotificationsPlugin();

    const callsChannel = AndroidNotificationChannel(
      _callsChannelId,
      _callsChannelName,
      description: _callsChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const messagesChannel = AndroidNotificationChannel(
      _messagesChannelId,
      _messagesChannelName,
      description: _messagesChannelDescription,
      importance: Importance.defaultImportance,
    );

    const generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      description: _generalChannelDescription,
      importance: Importance.low,
    );

    final androidPlugin =
        flutterLocalNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      AppLogger.warning(
        'Android notification plugin unavailable — channels not created',
        operation:
            'PushNotificationService._createAndroidNotificationChannels',
      );
      return;
    }

    await androidPlugin.createNotificationChannel(callsChannel);
    await androidPlugin.createNotificationChannel(messagesChannel);
    await androidPlugin.createNotificationChannel(generalChannel);

    AppLogger.debug(
      'Android notification channels created',
      operation: 'PushNotificationService._createAndroidNotificationChannels',
    );
  }

  // ---------------------------------------------------------------------------
  // Error handlers
  // ---------------------------------------------------------------------------

  void _handleTokenRefreshError(Object error, StackTrace stackTrace) {
    AppLogger.error(
      'FCM token refresh stream emitted an error',
      operation: 'PushNotificationService._handleTokenRefreshError',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
