import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/voice_message_chip.dart';

const Color _teal = AppColors.secondary;
const Color _metaColor = Color(0xFF9C8E82);

/// Renders a single message bubble with adaptive styling for sent vs received,
/// grouping position, media type, and delivery state.
class MessageBubbleWidget extends StatelessWidget {
  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isMine,
    required this.isGroupStart,
    required this.isGroupEnd,
    required this.participantName,
    required this.participantPhotoUrl,
  });

  final MessageItem message;
  final bool isMine;
  final bool isGroupStart;
  final bool isGroupEnd;
  final String participantName;
  final String? participantPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final topGap = isGroupStart ? 22.0 : 6.0;
    final time = _formatTime(message.sentAt);

    if (_isCallRecord(message.body)) {
      return CallChipWidget(body: message.body ?? '', time: time);
    }

    if (message.media?.type == MessageMediaType.image) {
      return _ImageMessage(
        message: message, isMine: isMine, isGroupStart: isGroupStart,
        isGroupEnd: isGroupEnd, topGap: topGap, time: time,
        participantName: participantName,
        participantPhotoUrl: participantPhotoUrl,
      );
    }

    final isVoice = message.media?.type == MessageMediaType.voice ||
        (message.body != null &&
            RegExp(r'^\[Voice message\]', caseSensitive: false)
                .hasMatch(message.body!));

    final Widget bubbleContent;
    if (message.isDeleted) {
      bubbleContent = Text(
        'This message was deleted.',
        style: AppTypography.bodySm.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      );
    } else if (isVoice) {
      bubbleContent = VoiceMessageChip(
        isMine: isMine,
        durationSeconds: message.media?.durationSeconds,
        audioUrl: message.media?.url,
      );
    } else {
      bubbleContent = Text(
        message.body ?? '',
        style: AppTypography.body.copyWith(
          fontSize: 15.5,
          height: 1.72,
          color: isMine ? Colors.white : const Color(0xFF1C140C),
          fontWeight: isMine ? FontWeight.w500 : FontWeight.w400,
        ),
      );
    }

    final borderRadius = _computeBorderRadius(isMine, isGroupStart, isGroupEnd);

    if (isMine) {
      return _MineBubble(
        topGap: topGap, borderRadius: borderRadius,
        isGroupEnd: isGroupEnd, time: time,
        deliveryState: message.deliveryState,
        child: bubbleContent,
      );
    }

    return _TheirBubble(
      topGap: topGap, borderRadius: borderRadius,
      isGroupStart: isGroupStart, isGroupEnd: isGroupEnd,
      time: time, participantName: participantName,
      participantPhotoUrl: participantPhotoUrl,
      child: bubbleContent,
    );
  }
}

// ─── Mine bubble ──────────────────────────────────────────────────────────

class _MineBubble extends StatelessWidget {
  const _MineBubble({
    required this.topGap, required this.borderRadius,
    required this.isGroupEnd, required this.time,
    required this.deliveryState, required this.child,
  });

  final double topGap;
  final BorderRadius borderRadius;
  final bool isGroupEnd;
  final String time;
  final MessageDeliveryState deliveryState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.74,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.5, -1), end: Alignment(0.5, 1),
                colors: [Color(0xFFE38A2F), Color(0xFFC86717), Color(0xFFB45312)],
              ),
              borderRadius: borderRadius,
              boxShadow: isGroupEnd
                  ? const [BoxShadow(color: Color(0x38A0460A), blurRadius: 28, offset: Offset(0, 14))]
                  : null,
            ),
            child: child,
          ),
          if (isGroupEnd) SentMetaRow(time: time, deliveryState: deliveryState),
        ],
      ),
    );
  }
}

// ─── Their bubble ─────────────────────────────────────────────────────────

class _TheirBubble extends StatelessWidget {
  const _TheirBubble({
    required this.topGap, required this.borderRadius,
    required this.isGroupStart, required this.isGroupEnd,
    required this.time, required this.participantName,
    required this.participantPhotoUrl, required this.child,
  });

  final double topGap;
  final BorderRadius borderRadius;
  final bool isGroupStart;
  final bool isGroupEnd;
  final String time;
  final String participantName;
  final String? participantPhotoUrl;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isGroupStart) PartnerLabel(name: participantName),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PartnerAvatar(name: participantName, photoUrl: participantPhotoUrl, isVisible: isGroupEnd),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.74),
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xF5F4FCFB), Color(0xFAFFFFFF)],
                    ),
                    borderRadius: borderRadius,
                    border: Border.all(color: _teal.withValues(alpha: 0.14), width: 1.5),
                    boxShadow: isGroupEnd
                        ? const [BoxShadow(color: Color(0x140F9D94), blurRadius: 28, offset: Offset(0, 14))]
                        : null,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
          if (isGroupEnd)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 5),
              child: Row(
                children: [
                  Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: _metaColor.withValues(alpha: 0.55))),
                  const SizedBox(width: 6),
                  Text(time, style: AppTypography.caption.copyWith(fontSize: 12.5, color: _metaColor)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Delivery meta ────────────────────────────────────────────────────────

/// Timestamp and delivery state icon for sent messages.
class SentMetaRow extends StatelessWidget {
  const SentMetaRow({super.key, required this.time, required this.deliveryState});

  final String time;
  final MessageDeliveryState deliveryState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(time, style: AppTypography.caption.copyWith(fontSize: 12.5, color: _metaColor)),
          const SizedBox(width: 5),
          _DeliveryIcon(state: deliveryState),
        ],
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({required this.state});

  final MessageDeliveryState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      MessageDeliveryState.sending => const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC8BFB6))),
        ),
      MessageDeliveryState.sent => const Icon(PhosphorIconsBold.check, size: 13, color: Color(0xFFC8BFB6)),
      MessageDeliveryState.delivered => const Icon(PhosphorIconsBold.checks, size: 13, color: Color(0xFFC8BFB6)),
      MessageDeliveryState.read => const Icon(PhosphorIconsBold.checks, size: 13, color: _teal),
      MessageDeliveryState.failed => Text('!', style: AppTypography.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w700)),
    };
  }
}

// ─── Partner widgets ──────────────────────────────────────────────────────

/// Small label above the first bubble in a received message group.
class PartnerLabel extends StatelessWidget {
  const PartnerLabel({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 54, bottom: 6),
      child: Text(name, style: AppTypography.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF7A6E64))),
    );
  }
}

/// Partner avatar shown at the bottom of a received message group.
class PartnerAvatar extends StatelessWidget {
  const PartnerAvatar({super.key, required this.name, required this.photoUrl, required this.isVisible});

  final String name;
  final String? photoUrl;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 40,
      child: isVisible
          ? CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF0F8F7),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: AppTypography.caption.copyWith(color: _teal))
                  : null,
            )
          : null,
    );
  }
}

// ─── Image message ────────────────────────────────────────────────────────

class _ImageMessage extends StatelessWidget {
  const _ImageMessage({
    required this.message, required this.isMine,
    required this.isGroupStart, required this.isGroupEnd,
    required this.topGap, required this.time,
    required this.participantName, required this.participantPhotoUrl,
  });

  final MessageItem message;
  final bool isMine;
  final bool isGroupStart;
  final bool isGroupEnd;
  final double topGap;
  final String time;
  final String participantName;
  final String? participantPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = message.media?.url;
    final borderRadius = _computeBorderRadius(isMine, isGroupStart, isGroupEnd);

    final imageWidget = imageUrl != null
        ? ClipRRect(
            borderRadius: borderRadius,
            child: CachedNetworkImage(
              imageUrl: imageUrl, width: 280, fit: BoxFit.cover,
              placeholder: (_, _) => const _ImagePlaceholder(),
              errorWidget: (_, _, _) => const _ImagePlaceholder(),
            ),
          )
        : const _ImagePlaceholder();

    if (isMine) {
      return Padding(
        padding: EdgeInsets.only(top: topGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            imageWidget,
            if (isGroupEnd) SentMetaRow(time: time, deliveryState: message.deliveryState),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isGroupStart) PartnerLabel(name: participantName),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PartnerAvatar(name: participantName, photoUrl: participantPhotoUrl, isVisible: isGroupEnd),
              const SizedBox(width: 10),
              imageWidget,
            ],
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200, height: 150,
      color: const Color(0x2EC4A88C),
      child: const Center(child: Icon(PhosphorIconsBold.image, size: 32)),
    );
  }
}

// ─── Call chip ─────────────────────────────────────────────────────────────

/// Renders a call activity record (missed/completed) centered in the thread.
class CallChipWidget extends StatelessWidget {
  const CallChipWidget({super.key, required this.body, required this.time});

  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    final isMissed = RegExp(r'missed', caseSensitive: false).hasMatch(body);
    final callLabel = body.replaceFirst(RegExp(r'^[\W\s]+'), '');
    final chipColor = isMissed ? AppColors.danger : _teal;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 470),
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: chipColor.withValues(alpha: 0.11),
            border: Border.all(color: chipColor.withValues(alpha: 0.24), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: chipColor.withValues(alpha: 0.14)),
                child: Icon(isMissed ? PhosphorIconsFill.phoneSlash : PhosphorIconsFill.phone, size: 16, color: chipColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(callLabel, style: AppTypography.label.copyWith(color: isMissed ? const Color(0xFF7A1A1A) : const Color(0xFF0A6860))),
                    Text(isMissed ? 'Call was not answered.' : 'Call activity was saved in this thread.', style: AppTypography.caption.copyWith(fontSize: 12.5, color: const Color(0xFF7A6E64))),
                  ],
                ),
              ),
              Text(time, style: AppTypography.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF7A6E64))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

BorderRadius _computeBorderRadius(bool isMine, bool isGroupStart, bool isGroupEnd) {
  if (isMine) {
    return BorderRadius.only(
      topLeft: const Radius.circular(26),
      topRight: Radius.circular(isGroupStart ? 26 : 10),
      bottomRight: Radius.circular(isGroupEnd ? 26 : 10),
      bottomLeft: const Radius.circular(26),
    );
  }
  return BorderRadius.only(
    topLeft: Radius.circular(isGroupStart ? 26 : 10),
    topRight: const Radius.circular(26),
    bottomRight: const Radius.circular(26),
    bottomLeft: Radius.circular(isGroupEnd ? 26 : 10),
  );
}

bool _isCallRecord(String? body) {
  if (body == null) return false;
  return RegExp(r'^\W*(Audio|Video)\s+Call\b', caseSensitive: false).hasMatch(body);
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:$minute $period';
}
