import 'package:flutter/material.dart';

/// Temporary stand-in screen for routes that will be built in later phases.
///
/// Displays a centred label so navigation can be visually verified before
/// real screens are wired in.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
