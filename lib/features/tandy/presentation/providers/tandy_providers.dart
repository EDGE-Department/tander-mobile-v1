import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/tandy/data/datasources/tandy_remote_datasource.dart';
import 'package:tander_flutter_v3/features/tandy/data/repositories/tandy_repository_impl.dart';
import 'package:tander_flutter_v3/features/tandy/domain/repositories/tandy_repository.dart';

// ─── Datasource ──────────────────────────────────────────────────────

final tandyRemoteDatasourceProvider =
    Provider<TandyRemoteDatasource>((ref) {
  return TandyRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

// ─── Repository ──────────────────────────────────────────────────────

final tandyRepositoryProvider = Provider<TandyRepository>((ref) {
  return TandyRepositoryImpl(
    remoteDatasource: ref.watch(tandyRemoteDatasourceProvider),
  );
});
