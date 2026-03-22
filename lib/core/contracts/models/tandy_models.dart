/// Tandy (AI assistant) domain models — consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
///
/// [TandyStructuredBlock] uses Dart sealed classes for the discriminated union
/// pattern, enabling exhaustive pattern matching in the UI layer.
///
/// Block data types (RecipeBlockData, GuideBlockData, SponsorBlockData, etc.)
/// live in `tandy_block_data_models.dart` to keep files under 400 lines.
library;

import 'package:flutter/foundation.dart';
import 'package:tander_flutter_v3/core/contracts/models/tandy_block_data_models.dart';

export 'package:tander_flutter_v3/core/contracts/models/tandy_block_data_models.dart';

// ── Structured Blocks (Sealed Class Hierarchy) ───────────────

/// Discriminated union of all Tandy structured content blocks.
///
/// Use exhaustive `switch` on this sealed class to guarantee every
/// variant is handled at compile time.
@immutable
sealed class TandyStructuredBlock {
  const TandyStructuredBlock({
    required this.blockId,
  });

  final String blockId;
}

@immutable
class RecipeBlock extends TandyStructuredBlock {
  const RecipeBlock({
    required super.blockId,
    required this.title,
    required this.recipeData,
  });

  final String title;
  final RecipeBlockData recipeData;

  @override
  String toString() => 'RecipeBlock(id: $blockId, title: $title)';
}

@immutable
class GuideBlock extends TandyStructuredBlock {
  const GuideBlock({
    required super.blockId,
    required this.title,
    required this.guideData,
  });

  final String title;
  final GuideBlockData guideData;

  @override
  String toString() => 'GuideBlock(id: $blockId, title: $title)';
}

@immutable
class SponsorCardBlock extends TandyStructuredBlock {
  const SponsorCardBlock({
    required super.blockId,
    required this.title,
    required this.sponsorData,
  });

  final String title;
  final SponsorBlockData sponsorData;

  @override
  String toString() =>
      'SponsorCardBlock(id: $blockId, title: $title)';
}

@immutable
class SafetyNoticeBlock extends TandyStructuredBlock {
  const SafetyNoticeBlock({
    required super.blockId,
    required this.notices,
  });

  final List<String> notices;

  @override
  String toString() =>
      'SafetyNoticeBlock(id: $blockId, notices: ${notices.length})';
}

@immutable
class QuickActionBlock extends TandyStructuredBlock {
  const QuickActionBlock({
    required super.blockId,
    required this.title,
    required this.actionLabel,
    required this.actionId,
  });

  final String title;
  final String actionLabel;
  final String actionId;

  @override
  String toString() =>
      'QuickActionBlock(id: $blockId, action: $actionLabel)';
}

// ── Tandy Message ────────────────────────────────────────────

/// Role of a message in a Tandy conversation.
enum TandyMessageRole {
  user,
  assistant,
}

@immutable
class TandyMessage {
  const TandyMessage({
    required this.messageId,
    required this.role,
    required this.body,
    required this.structuredBlocks,
    required this.sentAt,
    required this.isCardExpanded,
    required this.safetyNotices,
    this.detectedEmotion,
    this.domain,
  });

  final String messageId;
  final TandyMessageRole role;
  final String body;
  final List<TandyStructuredBlock> structuredBlocks;
  final DateTime sentAt;
  final bool isCardExpanded;
  final String? detectedEmotion;
  final String? domain;
  final List<String> safetyNotices;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TandyMessage &&
          runtimeType == other.runtimeType &&
          messageId == other.messageId;

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() => 'TandyMessage('
      'id: $messageId, '
      'role: ${role.name})';
}

// ── Tandy Thread ─────────────────────────────────────────────

@immutable
class TandyThread {
  const TandyThread({
    required this.conversationId,
    required this.createdAt,
    required this.language,
    required this.messages,
  });

  final String conversationId;
  final DateTime createdAt;
  final String language;
  final List<TandyMessage> messages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TandyThread &&
          runtimeType == other.runtimeType &&
          conversationId == other.conversationId;

  @override
  int get hashCode => conversationId.hashCode;

  @override
  String toString() => 'TandyThread('
      'id: $conversationId, '
      'messages: ${messages.length})';
}

// ── Tandy Send Result ────────────────────────────────────────

@immutable
class TandySendResult {
  const TandySendResult({
    required this.userMessage,
    required this.assistantMessage,
    required this.hasSponsorAd,
    required this.suggestBreathing,
    this.redirectAction,
  });

  final TandyMessage userMessage;
  final TandyMessage assistantMessage;
  final bool hasSponsorAd;
  final bool suggestBreathing;
  final String? redirectAction;

  @override
  String toString() => 'TandySendResult('
      'hasSponsor: $hasSponsorAd, '
      'redirect: $redirectAction)';
}

// ── Tandy Greeting ───────────────────────────────────────────

@immutable
class TandyGreeting {
  const TandyGreeting({
    required this.greeting,
    required this.suggestions,
  });

  final String greeting;
  final List<String> suggestions;

  @override
  String toString() => 'TandyGreeting(suggestions: ${suggestions.length})';
}
