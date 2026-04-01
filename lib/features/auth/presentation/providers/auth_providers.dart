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
