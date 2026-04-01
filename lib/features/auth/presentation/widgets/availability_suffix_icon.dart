import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Real-time availability status for email/phone text fields.
enum AvailabilityStatus { idle, checking, available, taken }

/// Suffix icon that reflects the current [AvailabilityStatus] of a field.
class AvailabilitySuffixIcon extends StatelessWidget {
  final AvailabilityStatus status;

  const AvailabilitySuffixIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) => switch (status) {
        AvailabilityStatus.idle => const SizedBox.shrink(),
        AvailabilityStatus.checking => const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
              ),
            ),
          ),
        AvailabilityStatus.available => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              PhosphorIconsRegular.checkCircle,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
        AvailabilityStatus.taken => const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              PhosphorIconsRegular.xCircle,
              color: Color(0xFFEF4444),
              size: 24,
            ),
          ),
      };
}
