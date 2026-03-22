import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';

/// [ChangeNotifier] that triggers a GoRouter refresh whenever auth state
/// changes.
///
/// GoRouter's `refreshListenable` accepts a [Listenable]. This adapter
/// bridges Riverpod's [authNotifierProvider] to that contract so the router
/// re-evaluates its `redirect` callback on every auth transition.
final class RouterListenable extends ChangeNotifier {
  RouterListenable(Ref ref) {
    _subscription = ref.listen(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
