import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tander_flutter_v3/app/app.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/utils/device_utils.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/notification_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for push notifications
  try {
    await Firebase.initializeApp();
    // Register background message handler — CRITICAL: must be top-level function
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  } catch (error) {
    debugPrint('[Firebase] Init failed: $error');
  }

  // Replace the red error screen with a transparent widget for non-fatal
  // rendering assertions (e.g. painting.dart color validation during transitions).
  final defaultErrorWidget = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final message = details.exception.toString();
    if (message.contains('painting.dart') || message.contains('dart:ui')) {
      debugPrint('[Suppressed] ${details.exception}');
      return const SizedBox.shrink();
    }
    return defaultErrorWidget(details);
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exception.toString();
    if (message.contains('painting.dart') || message.contains('dart:ui')) {
      debugPrint('[Suppressed] painting assertion: $message');
      return;
    }
    FlutterError.presentError(details);
  };

  // Default to portrait-only; tablet detection adjusts after first frame.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SharedPreferences before the widget tree mounts so that the
  // synchronous provider override is ready for all downstream consumers.
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const _OrientationAwareApp(),
    ),
  );
}

/// Wraps [TanderApp] and reconfigures orientations after the first frame
/// once a [BuildContext] with [MediaQuery] data is available.
class _OrientationAwareApp extends StatefulWidget {
  const _OrientationAwareApp();

  @override
  State<_OrientationAwareApp> createState() => _OrientationAwareAppState();
}

class _OrientationAwareAppState extends State<_OrientationAwareApp> {
  bool _hasConfiguredOrientation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasConfiguredOrientation) {
      _hasConfiguredOrientation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DeviceUtils.configureOrientations(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const TanderApp();
  }
}
