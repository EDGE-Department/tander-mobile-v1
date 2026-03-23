/// Card components for the Connections screen -- Request variant.
///
/// Other variants (SentCard, FriendRow) live in connection_card_variants.dart
/// to keep each file under 400 lines.
/// Matches web connection-cards.tsx pixel-for-pixel.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_avatar.dart';

// ── Helpers (shared with variants) ──────────────────────────────────

/// Formats a name with optional age for display.
/// Web: displayName(name, age) => age !== null ? `${name}, ${age}` : name
String formatConnectionDisplayName(String name, int? age) {
  if (age != null) return '$name, $age';
  return name;
}

/// Formats a DateTime as a human-friendly relative string.
/// Web: formatTimeAgo(date) matching secs/mins/hrs/days/months.
String formatConnectionTimeAgo(DateTime date) {
  final seconds = DateTime.now().difference(date).inSeconds;
  if (seconds < 60) return 'just now';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';
  final days = hours ~/ 24;
  if (days < 30) return '${days}d ago';
  return '${days ~/ 30}mo ago';
}

// ── Request Card ────────────────────────────────────────────────────

/// Incoming connection request card with accept + decline actions.
///
/// Web: rounded-3xl border bg-card shadow-xs, profile row with avatar xl,
/// name 15px extrabold, meta row (location + time), "Wants to connect" badge,
/// action footer with Pass (border-border bg-subtle) and Connect (gradient).
class RequestCard extends StatelessWidget {
  const RequestCard({
    required this.connection,
    required this.onAccept,
    required this.onDecline,
    required this.onViewProfile,
    required this.isLoading,
    super.key,
  });

  final ConnectionSummary connection;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onViewProfile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.warmXs,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileRow(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Web: flex w-full gap-4 p-4 text-left hover:bg-subtle/50
  Widget _buildProfileRow() {
    return GestureDetector(
      onTap: onViewProfile,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            TanderAvatar(
              imageUrl: connection.otherPhotoUrl,
              displayName: connection.otherUsername,
              size: TanderAvatarSize.xl,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildProfileInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Web: truncate text-[15px] font-extrabold leading-snug text-text-strong
        Text(
          formatConnectionDisplayName(
            connection.otherUsername,
            connection.otherAge,
          ),
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        _buildMetaRow(),
        const SizedBox(height: AppSpacing.xs),
        _buildWantsToConnectBadge(),
      ],
    );
  }

  /// Web: mt-0.5 flex items-center gap-1 text-[11px] text-text-muted
  Widget _buildMetaRow() {
    return Row(
      children: [
        if (connection.otherCity != null) ...[
          const Icon(Icons.location_on, size: 10, color: AppColors.textMuted),
          const SizedBox(width: 2),
          Text(
            connection.otherCity!,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '\u00B7',
              style: AppTypography.caption,
            ),
          ),
        ],
        Text(
          formatConnectionTimeAgo(connection.createdAt),
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  /// Web: inline-flex rounded-full border-secondary/25 bg-secondary/10 px-2.5 py-0.5
  Widget _buildWantsToConnectBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: AppRadius.borderFull,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        'Wants to connect',
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  /// Web: flex gap-2 border-t border-border/40 p-3
  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.40)),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Pass',
              icon: Icons.close,
              onTap: isLoading ? null : onDecline,
              backgroundColor: AppColors.subtle,
              foregroundColor: AppColors.textMuted,
              borderColor: AppColors.border,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _ActionButton(
              label: 'Connect',
              icon: Icons.check,
              onTap: isLoading ? null : onAccept,
              gradient: const LinearGradient(
                begin: Alignment(-0.7, -1),
                end: Alignment(0.7, 1),
                colors: [Color(0xFF0F9D94), Color(0xFF0A7C74)],
              ),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable action button ──────────────────────────────────────────

/// Touch-target-compliant action button used in card footers.
/// Web: min-h-[44px] flex-1 rounded-2xl, text-sm font-semibold/bold
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDisabled ? 0.50 : 1.0,
        child: Container(
          height: AppSpacing.touchMinimum,
          decoration: BoxDecoration(
            color: gradient == null ? backgroundColor : null,
            gradient: gradient,
            borderRadius: AppRadius.borderLg,
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
