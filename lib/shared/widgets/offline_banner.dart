/// Top banner displayed when the device loses network connectivity.
///
/// Slides in from the top with an [AnimatedSlide] and auto-dismisses
/// when connectivity is restored.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/utils/connectivity_monitor.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(isOnlineProvider);

    final bool isOffline = connectivityAsync.when(
      data: (isOnline) => !isOnline,
      loading: () => false,
      error: (_, _) => false,
    );

    return AnimatedSlide(
      offset: isOffline ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isOffline ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: isOffline ? const _BannerContent() : const SizedBox.shrink(),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.viewPaddingOf(context).top + AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: const BoxDecoration(color: AppColors.warning),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.textStrong),
          SizedBox(width: AppSpacing.xs),
          Text(
            'No internet connection',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
