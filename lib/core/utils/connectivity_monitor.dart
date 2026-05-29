/// Connectivity monitoring via connectivity_plus, exposed as a
/// Riverpod [StreamProvider] so any widget can react to online/offline
/// transitions.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the device has network connectivity, `false` otherwise.
///
/// Consumers should use `ref.watch(isOnlineProvider)` and handle the
/// [AsyncValue] states (loading, data, error).
final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map((
    List<ConnectivityResult> results,
  ) {
    return results.isNotEmpty &&
        !results.every(
          (connectivityResult) => connectivityResult == ConnectivityResult.none,
        );
  });
});
