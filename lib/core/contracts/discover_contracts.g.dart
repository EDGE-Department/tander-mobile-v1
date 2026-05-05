// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscoveryProfileDto _$DiscoveryProfileDtoFromJson(Map<String, dynamic> json) =>
    DiscoveryProfileDto(
      userId: json['userId'] as String,
      username: json['username'] as String,
      verified: json['verified'] as bool,
      online: json['online'] as bool,
      hasBeenSwiped: json['hasBeenSwiped'] as bool,
      hasLikedMe: json['hasLikedMe'] as bool,
      matched: json['matched'] as bool,
      displayName: json['displayName'] as String?,
      age: (json['age'] as num?)?.toInt(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      additionalPhotos: (json['additionalPhotos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lookingFor: (json['lookingFor'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      compatibilityScore: (json['compatibilityScore'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$DiscoveryProfileDtoToJson(
  DiscoveryProfileDto instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'age': instance.age,
  'city': instance.city,
  'country': instance.country,
  'location': instance.location,
  'bio': instance.bio,
  'profilePhotoUrl': instance.profilePhotoUrl,
  'additionalPhotos': instance.additionalPhotos,
  'interests': instance.interests,
  'lookingFor': instance.lookingFor,
  'verified': instance.verified,
  'online': instance.online,
  'hasBeenSwiped': instance.hasBeenSwiped,
  'hasLikedMe': instance.hasLikedMe,
  'matched': instance.matched,
  'compatibilityScore': instance.compatibilityScore,
  'distanceKm': instance.distanceKm,
};

DiscoveryFiltersDto _$DiscoveryFiltersDtoFromJson(Map<String, dynamic> json) =>
    DiscoveryFiltersDto(
      minAge: (json['minAge'] as num).toInt(),
      maxAge: (json['maxAge'] as num).toInt(),
      maxDistanceKm: (json['maxDistanceKm'] as num).toInt(),
      genderPreference: json['genderPreference'] as String?,
      lookingFor: json['lookingFor'] as String?,
    );

Map<String, dynamic> _$DiscoveryFiltersDtoToJson(
  DiscoveryFiltersDto instance,
) => <String, dynamic>{
  'minAge': instance.minAge,
  'maxAge': instance.maxAge,
  'maxDistanceKm': instance.maxDistanceKm,
  'genderPreference': instance.genderPreference,
  'lookingFor': instance.lookingFor,
};
