// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tandy_content_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeInstructionDto _$RecipeInstructionDtoFromJson(
  Map<String, dynamic> json,
) => RecipeInstructionDto(
  step: (json['step'] as num).toInt(),
  text: json['text'] as String,
  timerDurationMinutes: (json['timerDurationMinutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$RecipeInstructionDtoToJson(
  RecipeInstructionDto instance,
) => <String, dynamic>{
  'step': instance.step,
  'text': instance.text,
  'timerDurationMinutes': instance.timerDurationMinutes,
};

RecipeDto _$RecipeDtoFromJson(Map<String, dynamic> json) => RecipeDto(
  title: json['title'] as String,
  servings: (json['servings'] as num).toInt(),
  calories: (json['calories'] as num).toInt(),
  id: json['id'] as String?,
  image: json['image'] as String?,
  description: json['description'] as String?,
  prepTime: json['prepTime'] as String?,
  cookTime: json['cookTime'] as String?,
  difficulty: json['difficulty'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  instructions: (json['instructions'] as List<dynamic>?)
      ?.map((e) => RecipeInstructionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RecipeDtoToJson(RecipeDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'image': instance.image,
  'description': instance.description,
  'prepTime': instance.prepTime,
  'cookTime': instance.cookTime,
  'servings': instance.servings,
  'calories': instance.calories,
  'difficulty': instance.difficulty,
  'ingredients': instance.ingredients,
  'instructions': instance.instructions,
};

GuideStepDto _$GuideStepDtoFromJson(Map<String, dynamic> json) => GuideStepDto(
  step: (json['step'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  image: json['image'] as String?,
);

Map<String, dynamic> _$GuideStepDtoToJson(GuideStepDto instance) =>
    <String, dynamic>{
      'step': instance.step,
      'title': instance.title,
      'description': instance.description,
      'image': instance.image,
    };

GuideDto _$GuideDtoFromJson(Map<String, dynamic> json) => GuideDto(
  title: json['title'] as String,
  id: json['id'] as String?,
  category: json['category'] as String?,
  difficulty: json['difficulty'] as String?,
  duration: json['duration'] as String?,
  image: json['image'] as String?,
  steps: (json['steps'] as List<dynamic>?)
      ?.map((e) => GuideStepDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GuideDtoToJson(GuideDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'category': instance.category,
  'difficulty': instance.difficulty,
  'duration': instance.duration,
  'image': instance.image,
  'steps': instance.steps,
};

SponsorProductDto _$SponsorProductDtoFromJson(Map<String, dynamic> json) =>
    SponsorProductDto(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      productUrl: json['productUrl'] as String?,
    );

Map<String, dynamic> _$SponsorProductDtoToJson(SponsorProductDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'price': instance.price,
      'category': instance.category,
      'productUrl': instance.productUrl,
    };

SponsorLocationDto _$SponsorLocationDtoFromJson(Map<String, dynamic> json) =>
    SponsorLocationDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      distanceText: json['distanceText'] as String?,
    );

Map<String, dynamic> _$SponsorLocationDtoToJson(SponsorLocationDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'city': instance.city,
      'distanceText': instance.distanceText,
    };

SponsorAdDto _$SponsorAdDtoFromJson(Map<String, dynamic> json) => SponsorAdDto(
  sponsorId: json['sponsorId'] as String,
  sponsorName: json['sponsorName'] as String,
  sponsorType: json['sponsorType'] as String,
  recommendedProducts: (json['recommendedProducts'] as List<dynamic>)
      .map((e) => SponsorProductDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  sponsorLogoUrl: json['sponsorLogoUrl'] as String?,
  adContent: json['adContent'] as String?,
  sponsorWebsiteUrl: json['sponsorWebsiteUrl'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  nearestLocation: json['nearestLocation'] == null
      ? null
      : SponsorLocationDto.fromJson(
          json['nearestLocation'] as Map<String, dynamic>,
        ),
  disclaimer: json['disclaimer'] as String?,
  impressionId: json['impressionId'] as String?,
);

Map<String, dynamic> _$SponsorAdDtoToJson(SponsorAdDto instance) =>
    <String, dynamic>{
      'sponsorId': instance.sponsorId,
      'sponsorName': instance.sponsorName,
      'sponsorType': instance.sponsorType,
      'sponsorLogoUrl': instance.sponsorLogoUrl,
      'adContent': instance.adContent,
      'sponsorWebsiteUrl': instance.sponsorWebsiteUrl,
      'phoneNumber': instance.phoneNumber,
      'recommendedProducts': instance.recommendedProducts,
      'nearestLocation': instance.nearestLocation,
      'disclaimer': instance.disclaimer,
      'impressionId': instance.impressionId,
    };
