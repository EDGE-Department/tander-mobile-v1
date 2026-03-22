/// Tandy structured block data models — supporting types for
/// [TandyStructuredBlock] variants.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
library;

import 'package:flutter/foundation.dart';

// ── Recipe Structured Data ───────────────────────────────────

@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    this.amount,
    this.unit,
  });

  final String name;
  final String? amount;
  final String? unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredient &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          amount == other.amount &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(name, amount, unit);

  @override
  String toString() => 'RecipeIngredient($name)';
}

@immutable
class RecipeInstruction {
  const RecipeInstruction({
    required this.stepNumber,
    required this.text,
    this.timerDurationMinutes,
  });

  final int stepNumber;
  final String text;
  final int? timerDurationMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeInstruction &&
          runtimeType == other.runtimeType &&
          stepNumber == other.stepNumber &&
          text == other.text;

  @override
  int get hashCode => Object.hash(stepNumber, text);

  @override
  String toString() => 'RecipeInstruction(step: $stepNumber)';
}

@immutable
class RecipeBlockData {
  const RecipeBlockData({
    required this.recipeId,
    required this.servings,
    required this.calories,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    this.prepTime,
    this.cookTime,
    this.difficulty,
  });

  final String recipeId;
  final String? imageUrl;
  final String? prepTime;
  final String? cookTime;
  final int servings;
  final int calories;
  final String? difficulty;
  final List<String> ingredients;
  final List<RecipeInstruction> instructions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeBlockData &&
          runtimeType == other.runtimeType &&
          recipeId == other.recipeId;

  @override
  int get hashCode => recipeId.hashCode;

  @override
  String toString() => 'RecipeBlockData(id: $recipeId)';
}

// ── Guide Structured Data ────────────────────────────────────

@immutable
class GuideStep {
  const GuideStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  final int stepNumber;
  final String title;
  final String description;
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuideStep &&
          runtimeType == other.runtimeType &&
          stepNumber == other.stepNumber &&
          title == other.title;

  @override
  int get hashCode => Object.hash(stepNumber, title);

  @override
  String toString() => 'GuideStep(step: $stepNumber, title: $title)';
}

@immutable
class GuideBlockData {
  const GuideBlockData({
    required this.guideId,
    required this.steps,
    this.category,
    this.difficulty,
    this.duration,
    this.imageUrl,
  });

  final String guideId;
  final String? category;
  final String? difficulty;
  final String? duration;
  final String? imageUrl;
  final List<GuideStep> steps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuideBlockData &&
          runtimeType == other.runtimeType &&
          guideId == other.guideId;

  @override
  int get hashCode => guideId.hashCode;

  @override
  String toString() => 'GuideBlockData(id: $guideId)';
}

// ── Sponsor Structured Data ──────────────────────────────────

@immutable
class SponsorProduct {
  const SponsorProduct({
    required this.name,
    this.description,
    this.imageUrl,
    this.price,
  });

  final String name;
  final String? description;
  final String? imageUrl;
  final double? price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SponsorProduct &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'SponsorProduct($name)';
}

@immutable
class SponsorBlockData {
  const SponsorBlockData({
    required this.sponsorId,
    required this.sponsorName,
    required this.sponsorType,
    required this.products,
    this.logoUrl,
    this.message,
    this.websiteUrl,
    this.phoneNumber,
  });

  final String sponsorId;
  final String sponsorName;
  final String sponsorType;
  final String? logoUrl;
  final String? message;
  final String? websiteUrl;
  final String? phoneNumber;
  final List<SponsorProduct> products;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SponsorBlockData &&
          runtimeType == other.runtimeType &&
          sponsorId == other.sponsorId;

  @override
  int get hashCode => sponsorId.hashCode;

  @override
  String toString() =>
      'SponsorBlockData(id: $sponsorId, name: $sponsorName)';
}
