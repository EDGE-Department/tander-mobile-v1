/// Riverpod providers for the connection feature.
///
/// Wires datasource -> repository -> notifier following the same pattern
/// used by the discover module.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/connection/data/datasources/connection_remote_datasource.dart';
import 'package:tander_flutter_v3/features/connection/data/repositories/connection_repository_impl.dart';
import 'package:tander_flutter_v3/features/connection/domain/repositories/connection_repository.dart';

// ── Datasource ──────────────────────────────────────────────────────

final connectionRemoteDatasourceProvider =
    Provider<ConnectionRemoteDatasource>((ref) {
  return ConnectionRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

// ── Repository ──────────────────────────────────────────────────────

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  final currentUserId = sessionManager.session?.userId.toString() ?? '';

  return ConnectionRepositoryImpl(
    remoteDatasource: ref.watch(connectionRemoteDatasourceProvider),
    currentUserId: currentUserId,
  );
});
