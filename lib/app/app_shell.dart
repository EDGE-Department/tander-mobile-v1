import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';

/// Root scaffold for the authenticated app — body from GoRouter [ShellRoute],
/// bottom navigation dock pinned at the bottom with safe-area handling.
///
/// This is the Flutter equivalent of the web `AppShell` layout: a simple
/// `Scaffold` that composes the routed child with the branded nav bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  /// The routed page injected by GoRouter's `ShellRoute.builder`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const TanderBottomNavBar(),
    );
  }
}
