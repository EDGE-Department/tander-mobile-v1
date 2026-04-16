import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/storage/local_storage.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// SharedPreferences — must be overridden at startup in ProviderScope.overrides
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope at startup.',
  );
});

// ---------------------------------------------------------------------------
// Storage
// ---------------------------------------------------------------------------

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  const flutterSecureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return const SecureStorage(flutterSecureStorage);
});

// ---------------------------------------------------------------------------
// Session expired callback — placeholder until auth notifier is wired in Phase 3
// ---------------------------------------------------------------------------

final onSessionExpiredProvider = Provider<void Function()>((ref) {
  return () {
    // Phase 3 will override this with actual logout + navigate to login
  };
});

// ---------------------------------------------------------------------------
// Network — DioClient (creates its own Dio + interceptors internally)
// ---------------------------------------------------------------------------

/// Callback that syncs the refreshed access token into SessionManager.
/// Reads SessionManager lazily to avoid circular dependency.
final onTokenRefreshedProvider = Provider<void Function(String)>((ref) {
  return (String newToken) {
    try {
      // Late import: auth_providers imports core_providers, so we read lazily
      final sessionManager = ref.read(sessionManagerLateProvider);
      sessionManager?.updateAccessToken(newToken);
    } on Object {
      // SessionManager not yet available during early bootstrap — safe to ignore
    }
  };
});

/// Late-bound reference to SessionManager — set by auth layer after creation.
final sessionManagerLateProvider = StateProvider<SessionManager?>((ref) => null);

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    secureStorage: ref.watch(secureStorageProvider),
    onSessionExpired: ref.watch(onSessionExpiredProvider),
    onTokenRefreshed: ref.watch(onTokenRefreshedProvider),
  );
});

// ---------------------------------------------------------------------------
// Modal visibility — set true when a modal/sheet is open to hide bottom nav
// ---------------------------------------------------------------------------

final modalVisibleProvider = StateProvider<bool>((ref) => false);
