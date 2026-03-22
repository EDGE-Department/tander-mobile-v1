import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/push_notification_service.dart';

// ---------------------------------------------------------------------------
// Push notification service
// ---------------------------------------------------------------------------

/// Provides a singleton [PushNotificationService] wired to the app's
/// [DioClient] and [SharedPreferences].
///
/// Call `ref.read(pushNotificationServiceProvider).initialize()` after the
/// user authenticates to register the FCM token with the backend.
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    dioClient: ref.watch(dioClientProvider),
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});
