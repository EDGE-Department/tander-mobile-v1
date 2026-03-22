import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/calls_remote_datasource.dart';

// ---------------------------------------------------------------------------
// Datasources
// ---------------------------------------------------------------------------

final callsRemoteDatasourceProvider =
    Provider<CallsRemoteDatasource>((ref) {
  return CallsRemoteDatasource(dioClient: ref.watch(dioClientProvider));
});

// ---------------------------------------------------------------------------
// Re-exports for convenience
// ---------------------------------------------------------------------------
// The following providers are defined alongside their notifiers/classes:
//
// - callNotifierProvider         (call_notifier.dart)
// - callManagerProvider          (call_manager.dart)
// - callListenerProvider         (call_listener.dart)
//
// Import them directly from their respective files.
