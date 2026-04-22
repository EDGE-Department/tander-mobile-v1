// lib/features/auth/presentation/widgets/verification/responsive_layout.dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) mobileSmall;
  final Widget Function(BuildContext context, BoxConstraints constraints) mobileNormal;
  final Widget Function(BuildContext context, BoxConstraints constraints) tabletPortrait;
  final Widget Function(BuildContext context, BoxConstraints constraints) tabletLandscape;

  const ResponsiveLayout({
    Key? key,
    required this.mobileSmall,
    required this.mobileNormal,
    required this.tabletPortrait,
    required this.tabletLandscape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isLandscape = width > height;

        if (width < 375) {
          return mobileSmall(context, constraints);
        } else if (width < 600) {
          return mobileNormal(context, constraints);
        } else if (!isLandscape) {
          return tabletPortrait(context, constraints);
        } else {
          return tabletLandscape(context, constraints);
        }
      },
    );
  }
}
