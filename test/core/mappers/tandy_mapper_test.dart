import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/core/contracts/tandy_content_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/tandy_contracts.dart';
import 'package:tander_flutter_v3/core/mappers/tandy_mapper.dart';

// ── Fixture builders (explicit ids + ISO timestamps for determinism) ──

Map<String, Object?> _recipeJson({String id = 'recipe-001'}) => {
  'id': id,
  'title': 'Sinigang',
  'servings': 4,
  'calories': 300,
};

Map<String, Object?> _guideJson({String id = 'guide-001'}) => {
  'id': id,
  'title': 'How to stretch',
};

Map<String, Object?> _sponsorJson() => {
  'sponsorId': 'sp-1',
  'sponsorName': 'Acme',
  'sponsorType': 'retail',
  'recommendedProducts': [
    {'name': 'Vitamins', 'price': 9.99, 'category': 'health'},
  ],
};

Map<String, Object?> _msgJson({
  String id = 'm1',
  String role = 'assistant',
  String content = 'hello',
  Map<String, Object?>? recipe,
  Map<String, Object?>? guide,
  String? detectedEmotion,
}) => {
  'id': id,
  'role': role,
  'content': content,
  'timestamp': '2026-05-28T10:00:00Z',
  'recipe': ?recipe,
  'guide': ?guide,
  'detectedEmotion': ?detectedEmotion,
};

TandyMessageDto _msgDto({
  String role = 'assistant',
  Map<String, Object?>? recipe,
  Map<String, Object?>? guide,
  String? detectedEmotion,
}) => TandyMessageDto.fromJson(
  _msgJson(role: role, recipe: recipe, guide: guide, detectedEmotion: detectedEmotion),
);

TandySendMessageResponseDto _responseDto({
  Map<String, Object?>? assistantRecipe,
  Map<String, Object?>? responseRecipe,
  String? assistantEmotion,
  String? responseEmotion,
  List<String> safetyNotices = const [],
  Map<String, Object?>? sponsorAd,
  bool hasSponsorAd = false,
}) => TandySendMessageResponseDto.fromJson({
  'success': true,
  'userMessage': _msgJson(id: 'u1', role: 'user', content: 'hi'),
  'assistantMessage': _msgJson(
    id: 'a1',
    recipe: assistantRecipe,
    detectedEmotion: assistantEmotion,
  ),
  'suggestBreathing': false,
  'hasSponsorAd': hasSponsorAd,
  'safetyNotices': safetyNotices,
  'recipe': ?responseRecipe,
  'detectedEmotion': ?responseEmotion,
  'sponsorAd': ?sponsorAd,
});

void main() {
  group('mapTandyMessageDto', () {
    test('maps core fields and a valid ISO timestamp', () {
      final msg = mapTandyMessageDto(_msgDto());
      expect(msg.messageId, 'm1');
      expect(msg.body, 'hello');
      expect(msg.role, TandyMessageRole.assistant);
      expect(msg.sentAt, DateTime.utc(2026, 5, 28, 10));
      expect(msg.isCardExpanded, isFalse);
      expect(msg.safetyNotices, isEmpty);
      expect(msg.structuredBlocks, isEmpty);
    });

    test("role 'user' maps to user; everything else silently → assistant", () {
      expect(mapTandyMessageDto(_msgDto(role: 'user')).role,
          TandyMessageRole.user);
      // Pinned silent fallback: unknown / wrong-case / empty all → assistant.
      expect(mapTandyMessageDto(_msgDto(role: 'admin')).role,
          TandyMessageRole.assistant);
      expect(mapTandyMessageDto(_msgDto(role: 'User')).role,
          TandyMessageRole.assistant);
      expect(mapTandyMessageDto(_msgDto(role: '')).role,
          TandyMessageRole.assistant);
    });

    test('appends recipe and guide blocks with deterministic block ids', () {
      final msg = mapTandyMessageDto(
        _msgDto(recipe: _recipeJson(), guide: _guideJson()),
      );
      final recipe = msg.structuredBlocks.whereType<RecipeBlock>().single;
      final guide = msg.structuredBlocks.whereType<GuideBlock>().single;
      expect(recipe.blockId, 'recipe-001');
      expect(recipe.title, 'Sinigang');
      expect(guide.blockId, 'guide-001');
    });
  });

  group('block builders', () {
    test('sponsorAdToBlock derives a deterministic id from sponsorId', () {
      final block = sponsorAdToBlock(SponsorAdDto.fromJson(_sponsorJson()));
      expect(block, isA<SponsorCardBlock>());
      expect(block.blockId, 'sponsor-sp-1');
    });

    test('recipeToBlock uses the explicit recipe id when present', () {
      final block = recipeToBlock(RecipeDto.fromJson(_recipeJson(id: 'r-7')));
      expect(block.blockId, 'r-7');
    });
  });

  group('mapSendMessageResponse — passthrough', () {
    test('forwards top-level flags and maps both messages', () {
      final result = mapSendMessageResponse(
        _responseDto(hasSponsorAd: true),
      );
      expect(result.userMessage.role, TandyMessageRole.user);
      expect(result.assistantMessage.role, TandyMessageRole.assistant);
      expect(result.hasSponsorAd, isTrue);
      expect(result.suggestBreathing, isFalse);
    });
  });

  group('mapSendMessageResponse — recipe dedup', () {
    test('assistant already has a recipe → response recipe NOT re-added', () {
      final result = mapSendMessageResponse(
        _responseDto(
          assistantRecipe: _recipeJson(id: 'a-recipe'),
          responseRecipe: _recipeJson(id: 'resp-recipe'),
        ),
      );
      expect(
        result.assistantMessage.structuredBlocks.whereType<RecipeBlock>(),
        hasLength(1),
      );
    });

    test('assistant has no recipe → response recipe is added', () {
      final result = mapSendMessageResponse(
        _responseDto(responseRecipe: _recipeJson(id: 'resp-recipe')),
      );
      expect(
        result.assistantMessage.structuredBlocks.whereType<RecipeBlock>(),
        hasLength(1),
      );
    });
  });

  group('mapSendMessageResponse — emotion override only on reconstruction', () {
    test('with safety notices → response emotion wins', () {
      final result = mapSendMessageResponse(
        _responseDto(
          assistantEmotion: 'sad',
          responseEmotion: 'happy',
          safetyNotices: const ['take care'],
        ),
      );
      expect(result.assistantMessage.detectedEmotion, 'happy');
    });

    test('no extras → NOT reconstructed → response emotion is dropped', () {
      // Pinned trap: the override lives inside the reconstruction branch, so
      // with nothing to merge the assistant keeps its own emotion.
      final result = mapSendMessageResponse(
        _responseDto(assistantEmotion: 'sad', responseEmotion: 'happy'),
      );
      expect(result.assistantMessage.detectedEmotion, 'sad');
    });
  });

  group('mapSendMessageResponse — safety notices', () {
    test('non-empty notices add a SafetyNoticeBlock and set safetyNotices', () {
      final result = mapSendMessageResponse(
        _responseDto(safetyNotices: const ['notice-1', 'notice-2']),
      );
      expect(
        result.assistantMessage.structuredBlocks
            .whereType<SafetyNoticeBlock>(),
        hasLength(1),
      );
      expect(
        result.assistantMessage.safetyNotices,
        ['notice-1', 'notice-2'],
      );
    });

    test('empty notices → no block and safetyNotices stays empty', () {
      final result = mapSendMessageResponse(_responseDto());
      expect(
        result.assistantMessage.structuredBlocks
            .whereType<SafetyNoticeBlock>(),
        isEmpty,
      );
      expect(result.assistantMessage.safetyNotices, isEmpty);
    });
  });

  group('mapSendMessageResponse — sponsor', () {
    test('a sponsorAd adds a SponsorCardBlock', () {
      final result = mapSendMessageResponse(
        _responseDto(sponsorAd: _sponsorJson(), hasSponsorAd: true),
      );
      expect(
        result.assistantMessage.structuredBlocks
            .whereType<SponsorCardBlock>(),
        hasLength(1),
      );
    });
  });

  group('mapTandyConversationDto', () {
    TandyConversationDto convo({String? language}) =>
        TandyConversationDto.fromJson({
          'id': 'conv-1',
          'language': ?language,
          'createdAt': '2026-05-28T09:00:00Z',
          'updatedAt': '2026-05-28T09:30:00Z',
          'messages': [_msgJson(id: 'm1', role: 'user', content: 'hi')],
        });

    test('maps messages and a deterministic createdAt', () {
      final thread = mapTandyConversationDto(convo(language: 'tl'));
      expect(thread.conversationId, 'conv-1');
      expect(thread.language, 'tl');
      expect(thread.messages, hasLength(1));
      expect(thread.createdAt, DateTime.utc(2026, 5, 28, 9));
    });

    test("language defaults to 'en' when absent", () {
      expect(mapTandyConversationDto(convo()).language, 'en');
    });
  });

  group('buildTandyGreeting', () {
    test('passes greeting text and suggestions through', () {
      final greeting = buildTandyGreeting('Hi there', const ['a', 'b']);
      expect(greeting.greeting, 'Hi there');
      expect(greeting.suggestions, ['a', 'b']);
    });
  });
}
