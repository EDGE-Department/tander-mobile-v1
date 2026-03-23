import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/conversation_avatar_ring.dart';

const Color _orange = AppColors.primary;

/// A single conversation row with avatar, name, preview, unread badge,
/// entrance animation, and active-state styling.
///
/// Matches the web `ConversationRow` component pixel-for-pixel.
class ConversationRow extends StatefulWidget {
  const ConversationRow({
    super.key,
    required this.conversation,
    required this.isActive,
    required this.onTap,
    this.entranceDelay = Duration.zero,
  });

  final ConversationItem conversation;
  final bool isActive;
  final VoidCallback onTap;
  final Duration entranceDelay;

  @override
  State<ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends State<ConversationRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 6),
      end: Offset.zero,
    ).animate(_opacityAnimation);

    Future.delayed(widget.entranceDelay, () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) => Opacity(
        opacity: _opacityAnimation.value,
        child: Transform.translate(
          offset: _slideAnimation.value,
          child: child,
        ),
      ),
      child: _ConversationRowContent(
        conversation: widget.conversation,
        isActive: widget.isActive,
        onTap: widget.onTap,
      ),
    );
  }
}

// ---- Row content ---------------------------------------------------------

class _ConversationRowContent extends StatelessWidget {
  const _ConversationRowContent({
    required this.conversation,
    required this.isActive,
    required this.onTap,
  });

  final ConversationItem conversation;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread =
        conversation.unreadCount > 0 && !conversation.isMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderLg,
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onTap,
          hoverColor: const Color(0x0FE67E22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 68),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: AppRadius.borderLg,
              border: Border(
                left: BorderSide(
                  color: isActive ? _orange : Colors.transparent,
                  width: 3,
                ),
                top: BorderSide(
                  color: isActive
                      ? _orange.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
                right: BorderSide(
                  color: isActive
                      ? _orange.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
                bottom: BorderSide(
                  color: isActive
                      ? _orange.withValues(alpha: 0.18)
                      : Colors.transparent,
                ),
              ),
              boxShadow: isActive
                  ? const [
                      BoxShadow(
                        color: Color(0x1AE67E22),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                ConversationAvatarRing(
                  photoUrl: conversation.participant.profilePhotoUrl,
                  username: conversation.participant.username,
                  hasUnread: hasUnread,
                  isOnline: conversation.participant.isOnline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NameTimeRow(
                        participant: conversation.participant,
                        lastMessage: conversation.lastMessage,
                        hasUnread: hasUnread,
                      ),
                      const SizedBox(height: 4),
                      _PreviewBadgeRow(
                        lastMessage: conversation.lastMessage,
                        unreadCount: conversation.unreadCount,
                        hasUnread: hasUnread,
                      ),
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

// ---- Name + time row -----------------------------------------------------

class _NameTimeRow extends StatelessWidget {
  const _NameTimeRow({
    required this.participant,
    required this.lastMessage,
    required this.hasUnread,
  });

  final ParticipantSummary participant;
  final LastMessagePreview? lastMessage;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (participant.isOnline) ...[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F22C55E),
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
        ],
        Expanded(
          child: Text(
            participant.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontSize: 15.5,
              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF1A1209),
              letterSpacing: -0.015 * 15.5,
              height: 1.2,
            ),
          ),
        ),
        if (lastMessage != null) ...[
          const SizedBox(width: 8),
          Text(
            formatRelativeTime(lastMessage!.sentAt),
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: hasUnread
                  ? const Color(0xFF904C18)
                  : const Color(0xFF8A7E74),
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

// ---- Preview + badge row -------------------------------------------------

class _PreviewBadgeRow extends StatelessWidget {
  const _PreviewBadgeRow({
    required this.lastMessage,
    required this.unreadCount,
    required this.hasUnread,
  });

  final LastMessagePreview? lastMessage;
  final int unreadCount;
  final bool hasUnread;

  String get _previewText {
    if (lastMessage == null) return 'Start the conversation';
    if (lastMessage!.mediaType == MessageMediaType.image) return 'Photo';
    if (lastMessage!.mediaType == MessageMediaType.voice) {
      return 'Voice message';
    }
    final body = lastMessage!.body ?? '';
    final callPattern =
        RegExp(r'^\W*(Audio|Video)\s+Call', caseSensitive: false);
    if (callPattern.hasMatch(body)) {
      return body.replaceFirst(RegExp(r'^[\W\s]+'), '');
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _previewText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              fontSize: 13.5,
              color: hasUnread
                  ? const Color(0xFF3A2A1A)
                  : const Color(0xFF7A6E62),
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
        if (hasUnread) ...[
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderFull,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_orange, Color(0xFFF59E0B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _orange.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---- Helpers -------------------------------------------------------------

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
