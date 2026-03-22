import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tander_flutter_v3/app/app.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/utils/device_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
