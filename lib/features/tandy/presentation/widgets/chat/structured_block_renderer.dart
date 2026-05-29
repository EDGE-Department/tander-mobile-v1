import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/chat/guide_card.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/chat/recipe_card.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/chat/safety_notice_bar.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/chat/sponsor_card.dart';

/// Dispatcher that maps a [TandyStructuredBlock] to the appropriate
/// visual card component using exhaustive pattern matching.
class StructuredBlockRenderer extends StatelessWidget {
  const StructuredBlockRenderer({
    required this.block,
    required this.isExpanded,
    super.key,
  });

  final TandyStructuredBlock block;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      RecipeBlock(:final recipeData, :final title) => RecipeCardWidget(
        recipeData: recipeData,
        title: title,
        isExpanded: isExpanded,
      ),
      GuideBlock(:final guideData, :final title) => GuideCardWidget(
        guideData: guideData,
        title: title,
      ),
      SponsorCardBlock(:final sponsorData, :final title) => SponsorCardWidget(
        sponsorData: sponsorData,
        title: title,
        isExpanded: isExpanded,
      ),
      SafetyNoticeBlock(:final notices) => SafetyNoticeBarWidget(
        notices: notices,
      ),
      QuickActionBlock() => const SizedBox.shrink(),
    };
  }
}
