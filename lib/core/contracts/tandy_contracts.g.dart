// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tandy_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TandyMessageDto _$TandyMessageDtoFromJson(Map<String, dynamic> json) =>
    TandyMessageDto(
      id: (json['id'] as num).toInt(),
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
      recipe: json['recipe'] == null
          ? null
          : RecipeDto.fromJson(json['recipe'] as Map<String, dynamic>),
      guide: json['guide'] == null
          ? null
          : GuideDto.fromJson(json['guide'] as Map<String, dynamic>),
      status: json['status'] as String?,
      detectedEmotion: json['detectedEmotion'] as String?,
      detectedLanguage: json['detectedLanguage'] as String?,
      domain: json['domain'] as String?,
      cardExpanded: json['cardExpanded'] as bool?,
    );

Map<String, dynamic> _$TandyMessageDtoToJson(TandyMessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'timestamp': instance.timestamp,
      'recipe': instance.recipe,
      'guide': instance.guide,
      'status': instance.status,
      'detectedEmotion': instance.detectedEmotion,
      'detectedLanguage': instance.detectedLanguage,
      'domain': instance.domain,
      'cardExpanded': instance.cardExpanded,
    };

QuickActionDto _$QuickActionDtoFromJson(Map<String, dynamic> json) =>
    QuickActionDto(
      text: json['text'] as String,
      action: json['action'] as String,
    );

Map<String, dynamic> _$QuickActionDtoToJson(QuickActionDto instance) =>
    <String, dynamic>{'text': instance.text, 'action': instance.action};

TandyConversationDto _$TandyConversationDtoFromJson(
  Map<String, dynamic> json,
) => TandyConversationDto(
  id: (json['id'] as num).toInt(),
  language: json['language'] as String,
  messages: (json['messages'] as List<dynamic>)
      .map((e) => TandyMessageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  greeting: json['greeting'] as String?,
  quickActions: (json['quickActions'] as List<dynamic>?)
      ?.map((e) => QuickActionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TandyConversationDtoToJson(
  TandyConversationDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'language': instance.language,
  'messages': instance.messages,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'greeting': instance.greeting,
  'quickActions': instance.quickActions,
};

TandySendMessageResponseDto _$TandySendMessageResponseDtoFromJson(
  Map<String, dynamic> json,
) => TandySendMessageResponseDto(
  success: json['success'] as bool,
  userMessage: TandyMessageDto.fromJson(
    json['userMessage'] as Map<String, dynamic>,
  ),
  assistantMessage: TandyMessageDto.fromJson(
    json['assistantMessage'] as Map<String, dynamic>,
  ),
  suggestBreathing: json['suggestBreathing'] as bool,
  hasSponsorAd: json['hasSponsorAd'] as bool,
  safetyNotices: (json['safetyNotices'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  error: json['error'] as String?,
  redirectAction: json['redirectAction'] as String?,
  detectedEmotion: json['detectedEmotion'] as String?,
  sponsorAd: json['sponsorAd'] == null
      ? null
      : SponsorAdDto.fromJson(json['sponsorAd'] as Map<String, dynamic>),
  detectedLanguage: json['detectedLanguage'] as String?,
  recipe: json['recipe'] == null
      ? null
      : RecipeDto.fromJson(json['recipe'] as Map<String, dynamic>),
  guide: json['guide'] == null
      ? null
      : GuideDto.fromJson(json['guide'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TandySendMessageResponseDtoToJson(
  TandySendMessageResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'userMessage': instance.userMessage,
  'assistantMessage': instance.assistantMessage,
  'error': instance.error,
  'suggestBreathing': instance.suggestBreathing,
  'redirectAction': instance.redirectAction,
  'detectedEmotion': instance.detectedEmotion,
  'hasSponsorAd': instance.hasSponsorAd,
  'sponsorAd': instance.sponsorAd,
  'detectedLanguage': instance.detectedLanguage,
  'recipe': instance.recipe,
  'guide': instance.guide,
  'safetyNotices': instance.safetyNotices,
};

SendTandyMessageRequestDto _$SendTandyMessageRequestDtoFromJson(
  Map<String, dynamic> json,
) => SendTandyMessageRequestDto(
  message: json['message'] as String,
  language: json['language'] as String?,
);

Map<String, dynamic> _$SendTandyMessageRequestDtoToJson(
  SendTandyMessageRequestDto instance,
) => <String, dynamic>{
  'message': instance.message,
  'language': instance.language,
};

SetTandyLanguageRequestDto _$SetTandyLanguageRequestDtoFromJson(
  Map<String, dynamic> json,
) => SetTandyLanguageRequestDto(language: json['language'] as String);

Map<String, dynamic> _$SetTandyLanguageRequestDtoToJson(
  SetTandyLanguageRequestDto instance,
) => <String, dynamic>{'language': instance.language};
