import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

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

    // Get FCM token with timeout + retry (mirrors legacy app's TokenManager)
    String? fcmToken;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        fcmToken = await FirebaseMessaging.instance
            .getToken()
            .timeout(const Duration(seconds: 15));
        if (fcmToken != null) break;
      } catch (error) {
        AppLogger.warning(
          'FCM token attempt $attempt/3 failed: $error',
          operation: 'PushNotificationService.initialize',
        );
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }

    if (fcmToken != null) {
      await _registerToken(fcmToken);
    } else {
      AppLogger.warning(
        'FCM token unavailable after 3 attempts — push notifications disabled',
        operation: 'PushNotificationService.initialize',
      );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerToken,
      onError: _handleTokenRefreshError,
    );

    AppLogger.info(
      'Push notification service initialized',
      operation: 'PushNotificationService.initialize',
    );
  }

  /// Unregisters the current FCM token from the backend so the device
  /// stops receiving push notifications (e.g. on sign-out).
  Future<void> unregisterToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        AppLogger.warning(
          'No FCM token available to unregister',
          operation: 'PushNotificationService.unregisterToken',
        );
        return;
      }

      final encodedToken = Uri.encodeComponent(fcmToken);
      await _dioClient.delete<void>(
        '${ApiEndpoints.unregisterToken}?token=$encodedToken',
      );

      AppLogger.info(
        'FCM token unregistered from backend',
        operation: 'PushNotificationService.unregisterToken',
      );
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Failed to unregister FCM token',
        operation: 'PushNotificationService.unregisterToken',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info(
      'Notification permission status: ${settings.authorizationStatus.name}',
      operation: 'PushNotificationService._requestPermission',
    );
  }

  // ---------------------------------------------------------------------------
  // Token registration
  // ---------------------------------------------------------------------------

  Future<void> _registerToken(String fcmToken) async {
    final deviceId = _getOrCreateDeviceId();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    for (var attempt = 1; attempt <= 5; attempt++) {
      try {
        await _dioClient.post<Map<String, Object?>>(
          ApiEndpoints.registerToken,
          data: {
            'token': fcmToken,
            'platform': platform,
            'deviceId': deviceId,
            'tokenType': 'fcm',
          },
        );

        AppLogger.info(
          'FCM token registered with backend (attempt $attempt)',
          operation: 'PushNotificationService._registerToken',
          context: {'platform': platform, 'deviceId': deviceId},
        );
        return;
      } on Object catch (error) {
        AppLogger.warning(
          'FCM register attempt $attempt/5 failed: $error',
          operation: 'PushNotificationService._registerToken',
        );
        if (attempt < 5) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
    }
    AppLogger.error(
      'Failed to register FCM token after 5 attempts',
      operation: 'PushNotificationService._registerToken',
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
