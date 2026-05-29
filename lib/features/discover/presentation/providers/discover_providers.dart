import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:tander_flutter_v3/features/discover/data/repositories/discover_repository_impl.dart';
import 'package:tander_flutter_v3/features/discover/domain/repositories/discover_repository.dart';

// ─── Datasource ──────────────────────────────────────────────────────

final discoverRemoteDatasourceProvider = Provider<DiscoverRemoteDatasource>((
  ref,
) {
  return DiscoverRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

// ─── Repository ──────────────────────────────────────────────────────

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepositoryImpl(
    remoteDatasource: ref.watch(discoverRemoteDatasourceProvider),
  );
});
