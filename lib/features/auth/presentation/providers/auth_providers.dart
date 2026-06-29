import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:tander_flutter_v3/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tander_flutter_v3/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';
import 'package:tander_flutter_v3/features/auth/domain/usecases/register_usecase.dart';
import 'package:tander_flutter_v3/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:tander_flutter_v3/features/auth/domain/usecases/sign_out_usecase.dart';

// ---------------------------------------------------------------------------
// Datasources
// ---------------------------------------------------------------------------

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  return AuthLocalDatasource(
    secureStorage: ref.watch(secureStorageProvider),
    localStorage: ref.watch(localStorageProvider),
  );
});

// ---------------------------------------------------------------------------
// Session manager
// ---------------------------------------------------------------------------

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final manager = SessionManager(
    secureStorage: ref.watch(secureStorageProvider),
    dioClient: ref.watch(dioClientProvider),
  );
  // Wire the late-bound reference after initialization completes
  Future.microtask(() {
    ref.read(sessionManagerLateProvider.notifier).state = manager;
  });
  return manager;
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    localDatasource: ref.watch(authLocalDatasourceProvider),
    sessionManager: ref.watch(sessionManagerProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

// ---------------------------------------------------------------------------
// Verification config — minimum age (single source of truth)
// ---------------------------------------------------------------------------

/// Minimum eligible age, fetched once from `GET /auth/verification-config` so
/// the client mirrors the backend's (dynamically configurable) value instead of
/// a hardcoded constant. This prevents the client/server divergence that
/// trapped users at profile setup when the backend min-age was below the
/// client's hardcoded 60.
///
/// Resolves to `null` when the minimum is **unknown** — a failed fetch or an
/// unusable body. `null` is deliberate: callers FAIL OPEN (skip the client age
/// check) rather than substituting a restrictive default, because the backend's
/// mandatory ID age-gate is the real enforcer and a client fallback would only
/// re-trap eligible users. The repository call is `Result`-wrapped and never
/// throws, so the future always completes (to the backend value or `null`).
///
/// Not autoDispose — the value is cached for the session. A boot-time fetch
/// failure therefore pins this at `null` (fail open) until app restart; it does
/// not re-fetch on its own. This is an accepted trade-off given the gate is
/// UX-only and the backend remains the real enforcer.
final minimumAgeProvider = FutureProvider<int?>((ref) async {
  final result = await ref.watch(authRepositoryProvider).getMinimumAge();
  return result.valueOrNull;
});

// ---------------------------------------------------------------------------
// Use cases
// ---------------------------------------------------------------------------

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(repository: ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(repository: ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(repository: ref.watch(authRepositoryProvider));
});
