import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    secureStorage: ref.watch(secureStorageProvider),
    onSessionExpired: ref.watch(onSessionExpiredProvider),
  );
});
