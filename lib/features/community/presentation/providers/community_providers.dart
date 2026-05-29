/// Riverpod providers for the community feature — datasource, repository,
/// and notifier wiring.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/community/data/datasources/community_remote_datasource.dart';
import 'package:tander_flutter_v3/features/community/data/repositories/community_repository_impl.dart';
import 'package:tander_flutter_v3/features/community/domain/repositories/community_repository.dart';

// ─── Datasource ─────────────────────────────────────────────────────────

final communityRemoteDatasourceProvider = Provider<CommunityRemoteDatasource>((
  ref,
) {
  return CommunityRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

// ─── Repository ─────────────────────────────────────────────────────────

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(
    remoteDatasource: ref.watch(communityRemoteDatasourceProvider),
  );
});
