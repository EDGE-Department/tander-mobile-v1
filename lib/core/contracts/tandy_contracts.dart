/// Tandy domain -- raw backend DTOs matching the actual Spring Boot response
/// shapes.
///
/// Tandy content types (recipe, guide, sponsor) live in
/// [tandy_content_contracts.dart] to keep this file under 400 lines.
library;

import 'package:json_annotation/json_annotation.dart';

import 'package:tander_flutter_v3/core/contracts/tandy_content_contracts.dart';

part 'tandy_contracts.g.dart';

// ---------------------------------------------------------------------------
// Tandy message
// ---------------------------------------------------------------------------

/// TandyMessageDTO from the backend -- field names as Jackson serialises them.
@JsonSerializable()
class TandyMessageDto {
  const TandyMessageDto({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.recipe,
    this.guide,
    this.status,
    this.detectedEmotion,
    this.detectedLanguage,
    this.domain,
    this.cardExpanded,
  });

  factory TandyMessageDto.fromJson(Map<String, Object?> json) =>
      _$TandyMessageDtoFromJson(json);

  final int id;

  /// 'user' or 'assistant'
  final String role;
  final String content;

  /// ISO date string.
  final String timestamp;
  final RecipeDto? recipe;
  final GuideDto? guide;
  final String? status;
  final String? detectedEmotion;
  final String? detectedLanguage;
  final String? domain;
  final bool? cardExpanded;

  Map<String, Object?> toJson() => _$TandyMessageDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Quick action
// ---------------------------------------------------------------------------

@JsonSerializable()
class QuickActionDto {
  const QuickActionDto({
    required this.text,
    required this.action,
  });

  factory QuickActionDto.fromJson(Map<String, Object?> json) =>
      _$QuickActionDtoFromJson(json);

  final String text;
  final String action;

  Map<String, Object?> toJson() => _$QuickActionDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Tandy conversation
// ---------------------------------------------------------------------------

/// TandyConversationDTO from the backend.
@JsonSerializable()
class TandyConversationDto {
  const TandyConversationDto({
    required this.id,
    required this.language,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.greeting,
    this.quickActions,
  });

  factory TandyConversationDto.fromJson(Map<String, Object?> json) =>
      _$TandyConversationDtoFromJson(json);

  final int id;
  final String language;
  final List<TandyMessageDto> messages;
  final String createdAt;
  final String updatedAt;
  final String? greeting;
  final List<QuickActionDto>? quickActions;

  Map<String, Object?> toJson() => _$TandyConversationDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Send message response
// ---------------------------------------------------------------------------

/// TandySendMessageResponse from the backend.
@JsonSerializable()
class TandySendMessageResponseDto {
  const TandySendMessageResponseDto({
    required this.success,
    required this.userMessage,
    required this.assistantMessage,
    required this.suggestBreathing,
    required this.hasSponsorAd,
    required this.safetyNotices,
    this.error,
    this.redirectAction,
    this.detectedEmotion,
    this.sponsorAd,
    this.detectedLanguage,
    this.recipe,
    this.guide,
  });

  factory TandySendMessageResponseDto.fromJson(Map<String, Object?> json) =>
      _$TandySendMessageResponseDtoFromJson(json);

  final bool success;
  final TandyMessageDto userMessage;
  final TandyMessageDto assistantMessage;
  final String? error;
  final bool suggestBreathing;
  final String? redirectAction;
  final String? detectedEmotion;
  final bool hasSponsorAd;
  final SponsorAdDto? sponsorAd;
  final String? detectedLanguage;
  final RecipeDto? recipe;
  final GuideDto? guide;
  final List<String> safetyNotices;

  Map<String, Object?> toJson() =>
      _$TandySendMessageResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

@JsonSerializable()
class SendTandyMessageRequestDto {
  const SendTandyMessageRequestDto({
    required this.message,
    this.language,
  });

  factory SendTandyMessageRequestDto.fromJson(Map<String, Object?> json) =>
      _$SendTandyMessageRequestDtoFromJson(json);

  final String message;
  final String? language;

  Map<String, Object?> toJson() =>
      _$SendTandyMessageRequestDtoToJson(this);
}

@JsonSerializable()
class SetTandyLanguageRequestDto {
  const SetTandyLanguageRequestDto({required this.language});

  factory SetTandyLanguageRequestDto.fromJson(Map<String, Object?> json) =>
      _$SetTandyLanguageRequestDtoFromJson(json);

  final String language;

  Map<String, Object?> toJson() =>
      _$SetTandyLanguageRequestDtoToJson(this);
}
