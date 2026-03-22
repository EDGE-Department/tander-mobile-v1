import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/app/router/app_router.dart';
import 'package:tander_flutter_v3/core/theme/app_theme.dart';

/// Root application widget.
///
/// Wires [AppTheme.light] and the GoRouter from [appRouterProvider] into a
/// [MaterialApp.router]. Auth-driven navigation is handled entirely by the
/// router's redirect callback — this widget has no routing logic of its own.
final class TanderApp extends ConsumerWidget {
  const TanderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tander',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
