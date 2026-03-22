/// Maps Tandy DTOs to domain models.
///
/// The most complex mapper in the codebase: handles recipe/guide/sponsor
/// blocks, safety notices, emotion detection, and the rich send-message
/// response that merges response-level data into the assistant message.
library;

import 'package:tander_flutter_v3/core/contracts/tandy_content_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/tandy_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';

// ── Recipe DTO -> Block ───────────────────────────────────────────────

List<RecipeInstruction> _mapRecipeInstructions(RecipeDto dto) {
  return (dto.instructions ?? <RecipeInstructionDto>[])
      .map(
        (instruction) => RecipeInstruction(
          stepNumber: instruction.step,
          text: instruction.text,
          timerDurationMinutes: instruction.timerDurationMinutes,
        ),
      )
      .toList();
}

TandyStructuredBlock recipeToBlock(RecipeDto recipe) {
  final recipeData = RecipeBlockData(
    recipeId: recipe.id ?? 'recipe-${DateTime.now().millisecondsSinceEpoch}',
    imageUrl: recipe.image,
    prepTime: recipe.prepTime,
    cookTime: recipe.cookTime,
    servings: recipe.servings,
    calories: recipe.calories,
    difficulty: recipe.difficulty,
    ingredients: recipe.ingredients ?? const <String>[],
    instructions: _mapRecipeInstructions(recipe),
  );

  return RecipeBlock(
    blockId: recipeData.recipeId,
    title: recipe.title,
    recipeData: recipeData,
  );
}

// ── Guide DTO -> Block ────────────────────────────────────────────────

List<GuideStep> _mapGuideSteps(GuideDto dto) {
  return (dto.steps ?? <GuideStepDto>[])
      .map(
        (guideStep) => GuideStep(
          stepNumber: guideStep.step,
          title: guideStep.title,
          description: guideStep.description,
          imageUrl: guideStep.image,
        ),
      )
      .toList();
}

TandyStructuredBlock guideToBlock(GuideDto guide) {
  final guideData = GuideBlockData(
    guideId: guide.id ?? 'guide-${DateTime.now().millisecondsSinceEpoch}',
    category: guide.category,
    difficulty: guide.difficulty,
    duration: guide.duration,
    imageUrl: guide.image,
    steps: _mapGuideSteps(guide),
  );

  return GuideBlock(
    blockId: guideData.guideId,
    title: guide.title,
    guideData: guideData,
  );
}

// ── Safety Notices -> Block ───────────────────────────────────────────

TandyStructuredBlock safetyNoticesToBlock(List<String> notices) {
  return SafetyNoticeBlock(
    blockId: 'safety-${DateTime.now().millisecondsSinceEpoch}',
    notices: notices,
  );
}

// ── Sponsor Ad DTO -> Block ──────────────────────────────────────────

TandyStructuredBlock sponsorAdToBlock(SponsorAdDto sponsor) {
  return SponsorCardBlock(
    blockId: 'sponsor-${sponsor.sponsorId}',
    title: sponsor.sponsorName,
    sponsorData: SponsorBlockData(
      sponsorId: sponsor.sponsorId.toString(),
      sponsorName: sponsor.sponsorName,
      sponsorType: sponsor.sponsorType,
      logoUrl: sponsor.sponsorLogoUrl,
      message: sponsor.adContent,
      websiteUrl: sponsor.sponsorWebsiteUrl,
      phoneNumber: sponsor.phoneNumber,
      products: (sponsor.recommendedProducts)
          .map(
            (product) => SponsorProduct(
              name: product.name,
              description: product.description,
              imageUrl: product.thumbnailUrl ?? product.imageUrl,
              price: product.price,
            ),
          )
          .toList(),
    ),
  );
}

// ── Message DTO -> Model ─────────────────────────────────────────────

TandyMessage mapTandyMessageDto(TandyMessageDto dto) {
  final blocks = <TandyStructuredBlock>[];
  if (dto.recipe != null) blocks.add(recipeToBlock(dto.recipe!));
  if (dto.guide != null) blocks.add(guideToBlock(dto.guide!));

  return TandyMessage(
    messageId: dto.id.toString(),
    role: dto.role == 'user' ? TandyMessageRole.user : TandyMessageRole.assistant,
    body: dto.content,
    structuredBlocks: blocks,
    sentAt: DateTime.tryParse(dto.timestamp) ?? DateTime.now(),
    isCardExpanded: dto.cardExpanded ?? false,
    detectedEmotion: dto.detectedEmotion,
    domain: dto.domain,
    safetyNotices: const <String>[],
  );
}

// ── Send Response -> Rich Result ────────────────────────────────────

TandySendResult mapSendMessageResponse(TandySendMessageResponseDto dto) {
  final userMessage = mapTandyMessageDto(dto.userMessage);
  var assistantMessage = mapTandyMessageDto(dto.assistantMessage);

  final extraBlocks = <TandyStructuredBlock>[];

  if (dto.recipe != null) {
    final alreadyHasRecipe = assistantMessage.structuredBlocks
        .any((block) => block is RecipeBlock);
    if (!alreadyHasRecipe) extraBlocks.add(recipeToBlock(dto.recipe!));
  }

  if (dto.guide != null) {
    final alreadyHasGuide = assistantMessage.structuredBlocks
        .any((block) => block is GuideBlock);
    if (!alreadyHasGuide) extraBlocks.add(guideToBlock(dto.guide!));
  }

  if (dto.safetyNotices.isNotEmpty) {
    extraBlocks.add(safetyNoticesToBlock(dto.safetyNotices));
  }

  if (dto.sponsorAd != null) {
    extraBlocks.add(sponsorAdToBlock(dto.sponsorAd!));
  }

  if (extraBlocks.isNotEmpty || dto.safetyNotices.isNotEmpty) {
    assistantMessage = TandyMessage(
      messageId: assistantMessage.messageId,
      role: assistantMessage.role,
      body: assistantMessage.body,
      structuredBlocks: [
        ...assistantMessage.structuredBlocks,
        ...extraBlocks,
      ],
      sentAt: assistantMessage.sentAt,
      isCardExpanded: assistantMessage.isCardExpanded,
      detectedEmotion:
          dto.detectedEmotion ?? assistantMessage.detectedEmotion,
      domain: assistantMessage.domain,
      safetyNotices: dto.safetyNotices,
    );
  }

  return TandySendResult(
    userMessage: userMessage,
    assistantMessage: assistantMessage,
    hasSponsorAd: dto.hasSponsorAd,
    suggestBreathing: dto.suggestBreathing,
    redirectAction: dto.redirectAction,
  );
}

// ── Conversation DTO -> Thread ──────────────────────────────────────

TandyThread mapTandyConversationDto(TandyConversationDto dto) {
  return TandyThread(
    conversationId: dto.id.toString(),
    createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    language: dto.language,
    messages: dto.messages.map(mapTandyMessageDto).toList(),
  );
}

// ── Greeting ─────────────────────────────────────────────────────────

TandyGreeting buildTandyGreeting(
  String greetingText,
  List<String> defaultSuggestions,
) {
  return TandyGreeting(
    greeting: greetingText,
    suggestions: defaultSuggestions,
  );
}
