import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _teal = AppColors.secondary;

/// Placeholder screen for call history.
///
/// This will be fully implemented when the calls module is wired in.
/// For now it shows an empty state with navigation back to messages.
class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5ECE2), Color(0xFFEDE1D2)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(4, 10, 20, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFDF9),
                border: Border(
                  bottom: BorderSide(color: Color(0xCCEDE8DE)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Call History',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // Empty state
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _teal.withValues(alpha: 0.08),
                          border: Border.all(
                            color: _teal.withValues(alpha: 0.18),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 32,
                          color: _teal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No calls yet',
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your voice and video call history\nwill appear here.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          color: const Color(0xFF7C7165),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
