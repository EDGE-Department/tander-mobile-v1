import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/realtime/realtime_negotiate_datasource.dart';
import 'package:tander_flutter_v3/core/realtime/wps_client.dart';
import 'package:tander_flutter_v3/core/services/device_id_service.dart';
import 'package:tander_flutter_v3/core/storage/local_storage.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/calls_v2_remote_datasource.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_state.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_callkit_listener.dart';

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

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService(ref.watch(sharedPreferencesProvider));
});

// ---------------------------------------------------------------------------
// Session expired callback — placeholder until auth notifier is wired in Phase 3
// ---------------------------------------------------------------------------

// Overridden in main.dart with a ProviderContainer closure that calls
// authNotifierProvider.notifier.forceUnauthenticated() — the circular import
// between core_providers and auth_notifier is broken at the container level.
final onSessionExpiredProvider = Provider<void Function()>((ref) {
  return () {};
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
final sessionManagerLateProvider = StateProvider<SessionManager?>(
  (ref) => null,
);

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    secureStorage: ref.watch(secureStorageProvider),
    deviceIdService: ref.watch(deviceIdServiceProvider),
    onSessionExpired: ref.watch(onSessionExpiredProvider),
    onTokenRefreshed: ref.watch(onTokenRefreshedProvider),
  );
});

// ---------------------------------------------------------------------------
// Phase 5 — v2 calls + Web PubSub
// ---------------------------------------------------------------------------

final callsV2RemoteDatasourceProvider = Provider<CallsV2RemoteDatasource>((
  ref,
) {
  return CallsV2RemoteDatasource(
    dioClient: ref.watch(dioClientProvider),
    deviceIdService: ref.watch(deviceIdServiceProvider),
  );
});

final realtimeNegotiateDatasourceProvider =
    Provider<RealtimeNegotiateDatasource>((ref) {
      return RealtimeNegotiateDatasource(
        dioClient: ref.watch(dioClientProvider),
      );
    });

/// Singleton WPS subscriber. Auth layer owns lifecycle: `connect()` on
/// successful login, `disconnect()` on logout. App-foreground/background
/// is handled internally via [WidgetsBindingObserver].
final wpsClientProvider = Provider<WpsClient>((ref) {
  final client = WpsClient(
    negotiateDatasource: ref.watch(realtimeNegotiateDatasourceProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

/// Bridges `flutter_callkit_incoming` accept/decline events to the v2
/// REST endpoints + Twilio media connect. Auto-starts on first read so
/// app bootstrap just needs to `ref.read(v2CallkitListenerProvider)` once
/// to wire it up. Idempotent — multiple reads / hot-restarts are safe.
final v2CallkitListenerProvider = Provider<V2CallkitListener>((ref) {
  final listener = V2CallkitListener(
    datasource: ref.watch(callsV2RemoteDatasourceProvider),
    activeCall: ref.watch(v2ActiveCallProvider.notifier),
  );
  listener.start();
  ref.onDispose(listener.stop);
  return listener;
});

// ---------------------------------------------------------------------------
// Modal visibility — set true when a modal/sheet is open to hide bottom nav
// ---------------------------------------------------------------------------

final modalVisibleProvider = StateProvider<bool>((ref) => false);
