// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    UserProfileDto(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String?,
      nickName: json['nickName'] as String?,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      age: (json['age'] as num?)?.toInt(),
      birthDate: json['birthDate'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      civilStatus: json['civilStatus'] as String?,
      hobby: json['hobby'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      additionalPhotos: (json['additionalPhotos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      interests: json['interests'] as String?,
      lookingFor: json['lookingFor'] as String?,
      interestedIn: json['interestedIn'] as String?,
      religion: json['religion'] as String?,
      numberOfChildren: (json['numberOfChildren'] as num?)?.toInt(),
      languages: json['languages'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      verified: json['verified'] as bool?,
      profileCompleted: json['profileCompleted'] as bool?,
    );

Map<String, dynamic> _$UserProfileDtoToJson(UserProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'firstName': instance.firstName,
      'middleName': instance.middleName,
      'lastName': instance.lastName,
      'nickName': instance.nickName,
      'displayName': instance.displayName,
      'email': instance.email,
      'age': instance.age,
      'birthDate': instance.birthDate,
      'gender': instance.gender,
      'bio': instance.bio,
      'city': instance.city,
      'country': instance.country,
      'civilStatus': instance.civilStatus,
      'hobby': instance.hobby,
      'profilePhotoUrl': instance.profilePhotoUrl,
      'additionalPhotos': instance.additionalPhotos,
      'interests': instance.interests,
      'lookingFor': instance.lookingFor,
      'interestedIn': instance.interestedIn,
      'religion': instance.religion,
      'numberOfChildren': instance.numberOfChildren,
      'languages': instance.languages,
      'maritalStatus': instance.maritalStatus,
      'verified': instance.verified,
      'profileCompleted': instance.profileCompleted,
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

NotificationSettingsDto _$NotificationSettingsDtoFromJson(
  Map<String, dynamic> json,
) => NotificationSettingsDto(
  newMessages: json['newMessages'] as bool,
  newConnections: json['newConnections'] as bool,
  communityActivity: json['communityActivity'] as bool,
  tandyReminders: json['tandyReminders'] as bool,
  callNotifications: json['callNotifications'] as bool,
  emailNotifications: json['emailNotifications'] as bool,
);

Map<String, dynamic> _$NotificationSettingsDtoToJson(
  NotificationSettingsDto instance,
) => <String, dynamic>{
  'newMessages': instance.newMessages,
  'newConnections': instance.newConnections,
  'communityActivity': instance.communityActivity,
  'tandyReminders': instance.tandyReminders,
  'callNotifications': instance.callNotifications,
  'emailNotifications': instance.emailNotifications,
};

PrivacySettingsDto _$PrivacySettingsDtoFromJson(Map<String, dynamic> json) =>
    PrivacySettingsDto(
      profileVisibility: json['profileVisibility'] as String,
      showOnlineStatus: json['showOnlineStatus'] as bool,
      showLastSeen: json['showLastSeen'] as bool,
      allowConnectionRequests: json['allowConnectionRequests'] as bool,
    );

Map<String, dynamic> _$PrivacySettingsDtoToJson(PrivacySettingsDto instance) =>
    <String, dynamic>{
      'profileVisibility': instance.profileVisibility,
      'showOnlineStatus': instance.showOnlineStatus,
      'showLastSeen': instance.showLastSeen,
      'allowConnectionRequests': instance.allowConnectionRequests,
    };

ActiveSessionDto _$ActiveSessionDtoFromJson(Map<String, dynamic> json) =>
    ActiveSessionDto(
      sessionId: json['sessionId'] as String,
      device: json['device'] as String,
      lastActiveAt: json['lastActiveAt'] as String,
      isCurrent: json['isCurrent'] as bool,
    );

Map<String, dynamic> _$ActiveSessionDtoToJson(ActiveSessionDto instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'device': instance.device,
      'lastActiveAt': instance.lastActiveAt,
      'isCurrent': instance.isCurrent,
    };

SecuritySettingsDto _$SecuritySettingsDtoFromJson(Map<String, dynamic> json) =>
    SecuritySettingsDto(
      twoFactorEnabled: json['twoFactorEnabled'] as bool,
      activeSessions: (json['activeSessions'] as List<dynamic>)
          .map((e) => ActiveSessionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SecuritySettingsDtoToJson(
  SecuritySettingsDto instance,
) => <String, dynamic>{
  'twoFactorEnabled': instance.twoFactorEnabled,
  'activeSessions': instance.activeSessions,
};

DiscoverySettingsDto _$DiscoverySettingsDtoFromJson(
  Map<String, dynamic> json,
) => DiscoverySettingsDto(
  isDiscoverable: json['isDiscoverable'] as bool,
  minAge: (json['minAge'] as num).toInt(),
  maxAge: (json['maxAge'] as num).toInt(),
  maxDistanceKm: (json['maxDistanceKm'] as num).toInt(),
  genderPreference: json['genderPreference'] as String?,
);

Map<String, dynamic> _$DiscoverySettingsDtoToJson(
  DiscoverySettingsDto instance,
) => <String, dynamic>{
  'isDiscoverable': instance.isDiscoverable,
  'minAge': instance.minAge,
  'maxAge': instance.maxAge,
  'maxDistanceKm': instance.maxDistanceKm,
  'genderPreference': instance.genderPreference,
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
