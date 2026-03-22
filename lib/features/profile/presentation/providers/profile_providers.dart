import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:tander_flutter_v3/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:tander_flutter_v3/features/profile/domain/repositories/profile_repository.dart';

// ---------------------------------------------------------------------------
// Datasource
// ---------------------------------------------------------------------------

final profileRemoteDatasourceProvider =
    Provider<ProfileRemoteDatasource>((ref) {
  return ProfileRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDatasource: ref.watch(profileRemoteDatasourceProvider),
  );
});
