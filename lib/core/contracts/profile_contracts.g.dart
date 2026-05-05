// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: (json['id'] as num).toInt(),
      userId: json['userId'] as String,
      firstName: json['firstName'] as String?,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String?,
      nickName: json['nickName'] as String?,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      age: (json['age'] as num?)?.toInt(),
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      civilStatus: json['civilStatus'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      religion: json['religion'] as String?,
      numberOfChildren: (json['numberOfChildren'] as num?)?.toInt(),
      hobby: json['hobby'] as String?,
      interestedIn: json['interestedIn'] as String?,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lookingFor: (json['lookingFor'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      additionalPhotos: (json['additionalPhotos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      verified: json['verified'] as bool?,
      profileCompleted: json['profileCompleted'] as bool?,
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'firstName': instance.firstName,
      'middleName': instance.middleName,
      'lastName': instance.lastName,
      'nickName': instance.nickName,
      'displayName': instance.displayName,
      'email': instance.email,
      'age': instance.age,
      'dateOfBirth': instance.dateOfBirth,
      'gender': instance.gender,
      'bio': instance.bio,
      'city': instance.city,
      'country': instance.country,
      'civilStatus': instance.civilStatus,
      'maritalStatus': instance.maritalStatus,
      'religion': instance.religion,
      'numberOfChildren': instance.numberOfChildren,
      'hobby': instance.hobby,
      'interestedIn': instance.interestedIn,
      'interests': instance.interests,
      'lookingFor': instance.lookingFor,
      'languages': instance.languages,
      'profilePhotoUrl': instance.profilePhotoUrl,
      'additionalPhotos': instance.additionalPhotos,
      'verified': instance.verified,
      'profileCompleted': instance.profileCompleted,
    };

UserSettingsDto _$UserSettingsDtoFromJson(Map<String, dynamic> json) =>
    UserSettingsDto(
      showOnline: json['showOnline'] as bool,
      showLastSeen: json['showLastSeen'] as bool,
      showProfileViews: json['showProfileViews'] as bool,
      showAge: json['showAge'] as bool,
      readReceipts: json['readReceipts'] as bool,
      profileVisibility: json['profileVisibility'] as String,
      discoveryVisible: json['discoveryVisible'] as bool,
      discoveryMinAge: (json['discoveryMinAge'] as num).toInt(),
      discoveryMaxAge: (json['discoveryMaxAge'] as num).toInt(),
      discoveryMaxDistanceKm: (json['discoveryMaxDistanceKm'] as num).toInt(),
      notifyMessages: json['notifyMessages'] as bool,
      notifyMatches: json['notifyMatches'] as bool,
      notifyProfileViews: json['notifyProfileViews'] as bool,
      notifyCommunity: json['notifyCommunity'] as bool,
      notifyTandy: json['notifyTandy'] as bool,
      notifyCalls: json['notifyCalls'] as bool,
      quietHoursStart: json['quietHoursStart'] as String?,
      quietHoursEnd: json['quietHoursEnd'] as String?,
      twoFactorEnabled: json['twoFactorEnabled'] as bool,
      consentMarketing: json['consentMarketing'] as bool,
      consentAdPersonalization: json['consentAdPersonalization'] as bool,
      consentTandyMemory: json['consentTandyMemory'] as bool,
      familyAlertContactPhone: json['familyAlertContactPhone'] as String?,
      familyAlertContactLabel: json['familyAlertContactLabel'] as String?,
    );

Map<String, dynamic> _$UserSettingsDtoToJson(UserSettingsDto instance) =>
    <String, dynamic>{
      'showOnline': instance.showOnline,
      'showLastSeen': instance.showLastSeen,
      'showProfileViews': instance.showProfileViews,
      'showAge': instance.showAge,
      'readReceipts': instance.readReceipts,
      'profileVisibility': instance.profileVisibility,
      'discoveryVisible': instance.discoveryVisible,
      'discoveryMinAge': instance.discoveryMinAge,
      'discoveryMaxAge': instance.discoveryMaxAge,
      'discoveryMaxDistanceKm': instance.discoveryMaxDistanceKm,
      'notifyMessages': instance.notifyMessages,
      'notifyMatches': instance.notifyMatches,
      'notifyProfileViews': instance.notifyProfileViews,
      'notifyCommunity': instance.notifyCommunity,
      'notifyTandy': instance.notifyTandy,
      'notifyCalls': instance.notifyCalls,
      'quietHoursStart': instance.quietHoursStart,
      'quietHoursEnd': instance.quietHoursEnd,
      'twoFactorEnabled': instance.twoFactorEnabled,
      'consentMarketing': instance.consentMarketing,
      'consentAdPersonalization': instance.consentAdPersonalization,
      'consentTandyMemory': instance.consentTandyMemory,
      'familyAlertContactPhone': instance.familyAlertContactPhone,
      'familyAlertContactLabel': instance.familyAlertContactLabel,
    };

UpdateSettingsRequestDto _$UpdateSettingsRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateSettingsRequestDto(
  showOnline: json['showOnline'] as bool?,
  showLastSeen: json['showLastSeen'] as bool?,
  showProfileViews: json['showProfileViews'] as bool?,
  showAge: json['showAge'] as bool?,
  readReceipts: json['readReceipts'] as bool?,
  profileVisibility: json['profileVisibility'] as String?,
  discoveryVisible: json['discoveryVisible'] as bool?,
  discoveryMinAge: (json['discoveryMinAge'] as num?)?.toInt(),
  discoveryMaxAge: (json['discoveryMaxAge'] as num?)?.toInt(),
  discoveryMaxDistanceKm: (json['discoveryMaxDistanceKm'] as num?)?.toInt(),
  notifyMessages: json['notifyMessages'] as bool?,
  notifyMatches: json['notifyMatches'] as bool?,
  notifyProfileViews: json['notifyProfileViews'] as bool?,
  notifyCommunity: json['notifyCommunity'] as bool?,
  notifyTandy: json['notifyTandy'] as bool?,
  notifyCalls: json['notifyCalls'] as bool?,
  quietHoursStart: json['quietHoursStart'] as String?,
  quietHoursEnd: json['quietHoursEnd'] as String?,
  quietHoursStartSet: json['quietHoursStartSet'] as bool?,
  quietHoursEndSet: json['quietHoursEndSet'] as bool?,
  twoFactorEnabled: json['twoFactorEnabled'] as bool?,
  consentMarketing: json['consentMarketing'] as bool?,
  consentAdPersonalization: json['consentAdPersonalization'] as bool?,
  consentTandyMemory: json['consentTandyMemory'] as bool?,
);

Map<String, dynamic> _$UpdateSettingsRequestDtoToJson(
  UpdateSettingsRequestDto instance,
) => <String, dynamic>{
  if (instance.showOnline case final value?) 'showOnline': value,
  if (instance.showLastSeen case final value?) 'showLastSeen': value,
  if (instance.showProfileViews case final value?) 'showProfileViews': value,
  if (instance.showAge case final value?) 'showAge': value,
  if (instance.readReceipts case final value?) 'readReceipts': value,
  if (instance.profileVisibility case final value?) 'profileVisibility': value,
  if (instance.discoveryVisible case final value?) 'discoveryVisible': value,
  if (instance.discoveryMinAge case final value?) 'discoveryMinAge': value,
  if (instance.discoveryMaxAge case final value?) 'discoveryMaxAge': value,
  if (instance.discoveryMaxDistanceKm case final value?)
    'discoveryMaxDistanceKm': value,
  if (instance.notifyMessages case final value?) 'notifyMessages': value,
  if (instance.notifyMatches case final value?) 'notifyMatches': value,
  if (instance.notifyProfileViews case final value?)
    'notifyProfileViews': value,
  if (instance.notifyCommunity case final value?) 'notifyCommunity': value,
  if (instance.notifyTandy case final value?) 'notifyTandy': value,
  if (instance.notifyCalls case final value?) 'notifyCalls': value,
  if (instance.quietHoursStart case final value?) 'quietHoursStart': value,
  if (instance.quietHoursEnd case final value?) 'quietHoursEnd': value,
  if (instance.quietHoursStartSet case final value?)
    'quietHoursStartSet': value,
  if (instance.quietHoursEndSet case final value?) 'quietHoursEndSet': value,
  if (instance.twoFactorEnabled case final value?) 'twoFactorEnabled': value,
  if (instance.consentMarketing case final value?) 'consentMarketing': value,
  if (instance.consentAdPersonalization case final value?)
    'consentAdPersonalization': value,
  if (instance.consentTandyMemory case final value?)
    'consentTandyMemory': value,
};

UpdateProfileRequestDto _$UpdateProfileRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequestDto(
  firstName: json['firstName'] as String?,
  middleName: json['middleName'] as String?,
  lastName: json['lastName'] as String?,
  nickName: json['nickName'] as String?,
  bio: json['bio'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
  civilStatus: json['civilStatus'] as String?,
  interests: json['interests'] as String?,
  lookingFor: json['lookingFor'] as String?,
  birthDate: json['birthDate'] as String?,
  age: (json['age'] as num?)?.toInt(),
  gender: json['gender'] as String?,
  interestedIn: json['interestedIn'] as String?,
  hobby: json['hobby'] as String?,
  religion: json['religion'] as String?,
  numberOfChildren: (json['numberOfChildren'] as num?)?.toInt(),
  languages: json['languages'] as String?,
  maritalStatus: json['maritalStatus'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestDtoToJson(
  UpdateProfileRequestDto instance,
) => <String, dynamic>{
  if (instance.firstName case final value?) 'firstName': value,
  if (instance.middleName case final value?) 'middleName': value,
  if (instance.lastName case final value?) 'lastName': value,
  if (instance.nickName case final value?) 'nickName': value,
  if (instance.bio case final value?) 'bio': value,
  if (instance.city case final value?) 'city': value,
  if (instance.country case final value?) 'country': value,
  if (instance.civilStatus case final value?) 'civilStatus': value,
  if (instance.interests case final value?) 'interests': value,
  if (instance.lookingFor case final value?) 'lookingFor': value,
  if (instance.birthDate case final value?) 'birthDate': value,
  if (instance.age case final value?) 'age': value,
  if (instance.gender case final value?) 'gender': value,
  if (instance.interestedIn case final value?) 'interestedIn': value,
  if (instance.hobby case final value?) 'hobby': value,
  if (instance.religion case final value?) 'religion': value,
  if (instance.numberOfChildren case final value?) 'numberOfChildren': value,
  if (instance.languages case final value?) 'languages': value,
  if (instance.maritalStatus case final value?) 'maritalStatus': value,
};

ChangePasswordRequestDto _$ChangePasswordRequestDtoFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequestDto(
  currentPassword: json['currentPassword'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestDtoToJson(
  ChangePasswordRequestDto instance,
) => <String, dynamic>{
  'currentPassword': instance.currentPassword,
  'newPassword': instance.newPassword,
};
