import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _orange = AppColors.primary;

/// A single conversation row showing avatar, name, preview, and unread badge.
class ConversationRow extends StatelessWidget {
  const ConversationRow({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ConversationItem conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final participant = conversation.participant;
    final lastMessage = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0 && !conversation.isMuted;

    final previewText = lastMessage == null
        ? 'Start the conversation'
        : lastMessage.mediaType == MessageMediaType.image
            ? 'Photo'
            : lastMessage.mediaType == MessageMediaType.voice
                ? 'Voice message'
                : lastMessage.body ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ConversationAvatarRing(
                  photoUrl: participant.profilePhotoUrl,
                  username: participant.username,
                  hasUnread: hasUnread,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NameTimeRow(participant: participant, lastMessage: lastMessage, hasUnread: hasUnread),
                      const SizedBox(height: 4),
                      _PreviewBadgeRow(previewText: previewText, unreadCount: conversation.unreadCount, hasUnread: hasUnread),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Name + time row ──────────────────────────────────────────────────────

class _NameTimeRow extends StatelessWidget {
  const _NameTimeRow({required this.participant, required this.lastMessage, required this.hasUnread});

  final ParticipantSummary participant;
  final LastMessagePreview? lastMessage;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (participant.isOnline) ...[
          Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
          const SizedBox(width: 7),
        ],
        Expanded(
          child: Text(
            participant.username, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(fontSize: 15.5, fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF1A1209)),
          ),
        ),
        if (lastMessage != null)
          Text(
            formatRelativeTime(lastMessage!.sentAt),
            style: AppTypography.caption.copyWith(fontSize: 12, color: hasUnread ? const Color(0xFF904C18) : const Color(0xFF8A7E74), fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400),
          ),
      ],
    );
  }
}

// ─── Preview + badge row ──────────────────────────────────────────────────

class _PreviewBadgeRow extends StatelessWidget {
  const _PreviewBadgeRow({required this.previewText, required this.unreadCount, required this.hasUnread});

  final String previewText;
  final int unreadCount;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            previewText, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(fontSize: 13.5, color: hasUnread ? const Color(0xFF3A2A1A) : const Color(0xFF7A6E62), fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
        if (hasUnread)
          Container(
            constraints: const BoxConstraints(minWidth: 24), height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderFull,
              gradient: const LinearGradient(colors: [_orange, Color(0xFFF59E0B)]),
              boxShadow: [BoxShadow(color: _orange.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            alignment: Alignment.center,
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

// ─── Avatar ring ──────────────────────────────────────────────────────────

/// Circle avatar with an animated unread gradient ring.
class ConversationAvatarRing extends StatelessWidget {
  const ConversationAvatarRing({
    super.key,
    required this.photoUrl,
    required this.username,
    required this.hasUnread,
  });

  final String? photoUrl;
  final String username;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final avatarChild = CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFFEFAF4),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: AppTypography.h3.copyWith(color: _orange))
          : null,
    );

    if (!hasUnread) return avatarChild;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [_orange, Color(0xFFF7B23C)]),
      ),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFEFAF4)),
        child: avatarChild,
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

/// Formats a [DateTime] into a relative time string for conversation previews.
String formatRelativeTime(DateTime date) {
  final diffMs = DateTime.now().difference(date).inMilliseconds;
  final diffMins = diffMs ~/ 60000;
  final diffHours = diffMs ~/ 3600000;
  final diffDays = diffMs ~/ 86400000;

  if (diffMins < 1) return 'just now';
  if (diffMins < 60) return '${diffMins}m';
  if (diffHours < 24) return '${diffHours}h';
  if (diffDays < 7) return '${diffDays}d';

  return '${date.month}/${date.day}';
}
