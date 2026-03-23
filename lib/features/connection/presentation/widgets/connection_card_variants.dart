/// Sent and Friend card variants for the Connections screen.
/// Matches web connection-cards.tsx SentCard and FriendRow.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_card.dart';

// ── Sent Card ───────────────────────────────────────────────────────

/// Photo-grid card for outgoing connection request with cancel action.
class SentCard extends StatelessWidget {
  const SentCard({
    required this.connection,
    required this.onCancel,
    required this.onViewProfile,
    required this.isLoading,
    super.key,
  });

  final ConnectionSummary connection;
  final VoidCallback onCancel;
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
          _buildPhotoSection(),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: onViewProfile,
      child: AspectRatio(
        aspectRatio: 5 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPhoto(),
            _buildGradientOverlay(),
            _buildPendingBadge(),
            _buildNameOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (connection.otherPhotoUrl != null) {
      return CachedNetworkImage(
        imageUrl: connection.otherPhotoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => _photoPlaceholder(),
        errorWidget: (_, _, _) => _photoPlaceholder(),
      );
    }
    return _photoPlaceholder();
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xBF000000), Color(0x4D000000), Colors.transparent],
          stops: [0.0, 0.4, 0.7],
        ),
      ),
    );
  }

  Widget _buildPendingBadge() {
    return Positioned(
      right: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x4D000000),
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 9, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'PENDING',
              style: AppTypography.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameOverlay() {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatConnectionDisplayName(
              connection.otherUsername,
              connection.otherAge,
            ),
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (connection.otherCity != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 8,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    connection.otherCity!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: isLoading ? null : onCancel,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isLoading ? 0.50 : 1.0,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.subtle,
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.60),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Cancel',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Friend Row ──────────────────────────────────────────────────────

/// Horizontal row for an accepted connection with message + remove actions.
class FriendRow extends StatelessWidget {
  const FriendRow({
    required this.connection,
    required this.onMessage,
    required this.onRemove,
    required this.onViewProfile,
    required this.isLoading,
    super.key,
  });

  final ConnectionSummary connection;
  final VoidCallback onMessage;
  final VoidCallback onRemove;
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
      child: Row(
        children: [
          _buildThumbnail(),
          _buildInfo(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return GestureDetector(
      onTap: onViewProfile,
      child: SizedBox(
        width: 88,
        child: AspectRatio(
          aspectRatio: 1,
          child: connection.otherPhotoUrl != null
              ? CachedNetworkImage(
                  imageUrl: connection.otherPhotoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _photoPlaceholder(),
                  errorWidget: (_, _, _) => _photoPlaceholder(),
                )
              : _photoPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Expanded(
      child: GestureDetector(
        onTap: onViewProfile,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text(
                'Connected ${formatConnectionTimeAgo(connection.createdAt)}',
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
              if (connection.otherCity != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 9,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      connection.otherCity!,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connection.conversationId != null) ...[
            _CircleAction(
              icon: Icons.chat_bubble,
              color: AppColors.secondary,
              onTap: onMessage,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          _CircleAction(
            icon: Icons.person_remove,
            color: AppColors.textMuted,
            borderColor: AppColors.border,
            backgroundColor: AppColors.subtle,
            onTap: isLoading ? null : onRemove,
          ),
        ],
      ),
    );
  }
}

// ── Circle Action Button ────────────────────────────────────────────

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.50 : 1.0,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor ?? color,
            shape: BoxShape.circle,
            border:
                borderColor != null ? Border.all(color: borderColor!) : null,
            boxShadow: backgroundColor == null ? AppShadows.warmXs : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: backgroundColor != null ? color : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _photoPlaceholder() {
  return Container(
    color: AppColors.subtle,
    child: const Center(
      child: Icon(Icons.person, size: 24, color: AppColors.textMuted),
    ),
  );
}
