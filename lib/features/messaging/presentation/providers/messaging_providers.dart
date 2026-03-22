import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:tander_flutter_v3/features/messaging/data/datasources/messaging_stomp_datasource.dart';
import 'package:tander_flutter_v3/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:tander_flutter_v3/features/messaging/domain/repositories/messaging_repository.dart';

// ─── Datasources ────────────────────────────────────────────────────────

final messagingRemoteDatasourceProvider =
    Provider<MessagingRemoteDatasource>((ref) {
  return MessagingRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

final messagingStompDatasourceProvider =
    Provider<MessagingStompDatasource>((ref) {
  return const MessagingStompDatasource();
});

// ─── Repository ─────────────────────────────────────────────────────────

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepositoryImpl(
    remoteDatasource: ref.watch(messagingRemoteDatasourceProvider),
  );
});

// ─── Current user ID ────────────────────────────────────────────────────

/// Provides the authenticated user's ID as a [String] for use in mappers
/// and notifiers.
///
/// Throws if no session exists (should only be consumed inside auth guards).
final currentUserIdProvider = Provider<String>((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  final session = sessionManager.session;
  if (session == null) {
    throw StateError('currentUserIdProvider accessed without active session');
  }
  return session.userId.toString();
});
