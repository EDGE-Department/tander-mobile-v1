/// Tandy content types -- recipe, guide, and sponsor DTOs.
/// Split from [tandy_contracts.dart] to keep each file under 400 lines.
library;

import 'package:json_annotation/json_annotation.dart';

part 'tandy_content_contracts.g.dart';

// ---------------------------------------------------------------------------
// Recipe
// ---------------------------------------------------------------------------

@JsonSerializable()
class RecipeInstructionDto {
  const RecipeInstructionDto({
    required this.step,
    required this.text,
    this.timerDurationMinutes,
  });

  factory RecipeInstructionDto.fromJson(Map<String, Object?> json) =>
      _$RecipeInstructionDtoFromJson(json);

  final int step;
  final String text;
  final int? timerDurationMinutes;

  Map<String, Object?> toJson() => _$RecipeInstructionDtoToJson(this);
}

@JsonSerializable()
class RecipeDto {
  const RecipeDto({
    required this.title,
    required this.servings,
    required this.calories,
    this.id,
    this.image,
    this.description,
    this.prepTime,
    this.cookTime,
    this.difficulty,
    this.ingredients,
    this.instructions,
  });

  factory RecipeDto.fromJson(Map<String, Object?> json) =>
      _$RecipeDtoFromJson(json);

  final String? id;
  final String title;
  final String? image;
  final String? description;
  final String? prepTime;
  final String? cookTime;
  final int servings;
  final int calories;
  final String? difficulty;
  final List<String>? ingredients;
  final List<RecipeInstructionDto>? instructions;

  Map<String, Object?> toJson() => _$RecipeDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Guide
// ---------------------------------------------------------------------------

@JsonSerializable()
class GuideStepDto {
  const GuideStepDto({
    required this.step,
    required this.title,
    required this.description,
    this.image,
  });

  factory GuideStepDto.fromJson(Map<String, Object?> json) =>
      _$GuideStepDtoFromJson(json);

  final int step;
  final String title;
  final String description;
  final String? image;

  Map<String, Object?> toJson() => _$GuideStepDtoToJson(this);
}

@JsonSerializable()
class GuideDto {
  const GuideDto({
    required this.title,
    this.id,
    this.category,
    this.difficulty,
    this.duration,
    this.image,
    this.steps,
  });

  factory GuideDto.fromJson(Map<String, Object?> json) =>
      _$GuideDtoFromJson(json);

  final String? id;
  final String title;
  final String? category;
  final String? difficulty;
  final String? duration;
  final String? image;
  final List<GuideStepDto>? steps;

  Map<String, Object?> toJson() => _$GuideDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Sponsor
// ---------------------------------------------------------------------------

@JsonSerializable()
class SponsorProductDto {
  const SponsorProductDto({
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.imageUrl,
    this.thumbnailUrl,
    this.productUrl,
  });

  factory SponsorProductDto.fromJson(Map<String, Object?> json) =>
      _$SponsorProductDtoFromJson(json);

  final String name;
  final String? description;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double price;
  final String category;
  final String? productUrl;

  Map<String, Object?> toJson() => _$SponsorProductDtoToJson(this);
}

@JsonSerializable()
class SponsorLocationDto {
  const SponsorLocationDto({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.distanceText,
  });

  factory SponsorLocationDto.fromJson(Map<String, Object?> json) =>
      _$SponsorLocationDtoFromJson(json);

  final int id;
  final String name;
  final String address;
  final String city;
  final String? distanceText;

  Map<String, Object?> toJson() => _$SponsorLocationDtoToJson(this);
}

/// SponsorAdDTO from the backend.
@JsonSerializable()
class SponsorAdDto {
  const SponsorAdDto({
    required this.sponsorId,
    required this.sponsorName,
    required this.sponsorType,
    required this.recommendedProducts,
    this.sponsorLogoUrl,
    this.adContent,
    this.sponsorWebsiteUrl,
    this.phoneNumber,
    this.nearestLocation,
    this.disclaimer,
    this.impressionId,
  });

  factory SponsorAdDto.fromJson(Map<String, Object?> json) =>
      _$SponsorAdDtoFromJson(json);

  /// UUID — backend serialises as string.
  final String sponsorId;
  final String sponsorName;
  final String sponsorType;
  final String? sponsorLogoUrl;
  final String? adContent;
  final String? sponsorWebsiteUrl;
  final String? phoneNumber;
  final List<SponsorProductDto> recommendedProducts;
  final SponsorLocationDto? nearestLocation;
  final String? disclaimer;

  /// Echo of the impression row id — client posts back on CTA tap so CTR can be measured.
  final String? impressionId;

  Map<String, Object?> toJson() => _$SponsorAdDtoToJson(this);
}
