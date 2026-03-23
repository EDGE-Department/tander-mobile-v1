// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_contracts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    LoginRequestDto(
      identifier: json['identifier'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'password': instance.password,
    };

LoginResponseDataDto _$LoginResponseDataDtoFromJson(
  Map<String, dynamic> json,
) => LoginResponseDataDto(
  refreshToken: json['refreshToken'] as String,
  userId: json['userId'],
  email: json['email'] as String?,
  username: json['username'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  registrationPhase: json['registrationPhase'] as String?,
  emailVerified: json['emailVerified'] as bool?,
  idVerified: json['idVerified'] as bool?,
  profileCompleted: json['profileCompleted'] as bool?,
  idVerificationStatus: json['idVerificationStatus'] as String?,
  profilePhotoUrl: json['profilePhotoUrl'] as String?,
);

Map<String, dynamic> _$LoginResponseDataDtoToJson(
  LoginResponseDataDto instance,
) => <String, dynamic>{
  'refreshToken': instance.refreshToken,
  'userId': instance.userId,
  'email': instance.email,
  'username': instance.username,
  'phoneNumber': instance.phoneNumber,
  'registrationPhase': instance.registrationPhase,
  'emailVerified': instance.emailVerified,
  'idVerified': instance.idVerified,
  'profileCompleted': instance.profileCompleted,
  'idVerificationStatus': instance.idVerificationStatus,
  'profilePhotoUrl': instance.profilePhotoUrl,
};

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      success: json['success'] as bool,
      data: LoginResponseDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseDtoToJson(LoginResponseDto instance) =>
    <String, dynamic>{'success': instance.success, 'data': instance.data};

RegisterRequestDto _$RegisterRequestDtoFromJson(Map<String, dynamic> json) =>
    RegisterRequestDto(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      gender: json['gender'] as String,
      phone: json['phone'] as String?,
      username: json['username'] as String?,
    );

Map<String, dynamic> _$RegisterRequestDtoToJson(RegisterRequestDto instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'username': instance.username,
      'password': instance.password,
      'dateOfBirth': instance.dateOfBirth,
      'gender': instance.gender,
    };

RegisterResponseDataDto _$RegisterResponseDataDtoFromJson(
  Map<String, dynamic> json,
) => RegisterResponseDataDto(
  userId: json['userId'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  registrationPhase: json['registrationPhase'] as String,
);

Map<String, dynamic> _$RegisterResponseDataDtoToJson(
  RegisterResponseDataDto instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'email': instance.email,
  'username': instance.username,
  'registrationPhase': instance.registrationPhase,
};

RegisterResponseDto _$RegisterResponseDtoFromJson(Map<String, dynamic> json) =>
    RegisterResponseDto(
      success: json['success'] as bool,
      data: RegisterResponseDataDto.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$RegisterResponseDtoToJson(
  RegisterResponseDto instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

SendOtpRequestDto _$SendOtpRequestDtoFromJson(Map<String, dynamic> json) =>
    SendOtpRequestDto(
      contact: json['contact'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$SendOtpRequestDtoToJson(SendOtpRequestDto instance) =>
    <String, dynamic>{'contact': instance.contact, 'type': instance.type};

VerifyRegistrationOtpRequestDto _$VerifyRegistrationOtpRequestDtoFromJson(
  Map<String, dynamic> json,
) => VerifyRegistrationOtpRequestDto(
  contact: json['contact'] as String,
  otp: json['otp'] as String,
);

Map<String, dynamic> _$VerifyRegistrationOtpRequestDtoToJson(
  VerifyRegistrationOtpRequestDto instance,
) => <String, dynamic>{'contact': instance.contact, 'otp': instance.otp};

ForgotPasswordRequestDto _$ForgotPasswordRequestDtoFromJson(
  Map<String, dynamic> json,
) => ForgotPasswordRequestDto(
  email: json['email'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
);

Map<String, dynamic> _$ForgotPasswordRequestDtoToJson(
  ForgotPasswordRequestDto instance,
) => <String, dynamic>{
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
};

VerifyResetOtpRequestDto _$VerifyResetOtpRequestDtoFromJson(
  Map<String, dynamic> json,
) => VerifyResetOtpRequestDto(
  code: json['code'] as String,
  email: json['email'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
);

Map<String, dynamic> _$VerifyResetOtpRequestDtoToJson(
  VerifyResetOtpRequestDto instance,
) => <String, dynamic>{
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'code': instance.code,
};

VerifyResetOtpResponseDataDto _$VerifyResetOtpResponseDataDtoFromJson(
  Map<String, dynamic> json,
) => VerifyResetOtpResponseDataDto(resetToken: json['resetToken'] as String);

Map<String, dynamic> _$VerifyResetOtpResponseDataDtoToJson(
  VerifyResetOtpResponseDataDto instance,
) => <String, dynamic>{'resetToken': instance.resetToken};

VerifyResetOtpResponseDto _$VerifyResetOtpResponseDtoFromJson(
  Map<String, dynamic> json,
) => VerifyResetOtpResponseDto(
  success: json['success'] as bool,
  data: VerifyResetOtpResponseDataDto.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
  message: json['message'] as String?,
);

Map<String, dynamic> _$VerifyResetOtpResponseDtoToJson(
  VerifyResetOtpResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ResetPasswordRequestDto _$ResetPasswordRequestDtoFromJson(
  Map<String, dynamic> json,
) => ResetPasswordRequestDto(
  newPassword: json['newPassword'] as String,
  resetToken: json['resetToken'] as String,
  email: json['email'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
);

Map<String, dynamic> _$ResetPasswordRequestDtoToJson(
  ResetPasswordRequestDto instance,
) => <String, dynamic>{
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'newPassword': instance.newPassword,
  'resetToken': instance.resetToken,
};

VerifyEmailRequestDto _$VerifyEmailRequestDtoFromJson(
  Map<String, dynamic> json,
) => VerifyEmailRequestDto(token: json['token'] as String);

Map<String, dynamic> _$VerifyEmailRequestDtoToJson(
  VerifyEmailRequestDto instance,
) => <String, dynamic>{'token': instance.token};

ResendVerificationRequestDto _$ResendVerificationRequestDtoFromJson(
  Map<String, dynamic> json,
) => ResendVerificationRequestDto(email: json['email'] as String);

Map<String, dynamic> _$ResendVerificationRequestDtoToJson(
  ResendVerificationRequestDto instance,
) => <String, dynamic>{'email': instance.email};

IdVerificationRequestDto _$IdVerificationRequestDtoFromJson(
  Map<String, dynamic> json,
) => IdVerificationRequestDto(
  idType: json['idType'] as String,
  idNumber: json['idNumber'] as String,
);

Map<String, dynamic> _$IdVerificationRequestDtoToJson(
  IdVerificationRequestDto instance,
) => <String, dynamic>{
  'idType': instance.idType,
  'idNumber': instance.idNumber,
};

CheckAvailabilityResponseDto _$CheckAvailabilityResponseDtoFromJson(
  Map<String, dynamic> json,
) => CheckAvailabilityResponseDto(available: json['available'] as bool);

Map<String, dynamic> _$CheckAvailabilityResponseDtoToJson(
  CheckAvailabilityResponseDto instance,
) => <String, dynamic>{'available': instance.available};

ApiSuccessResponseDto _$ApiSuccessResponseDtoFromJson(
  Map<String, dynamic> json,
) => ApiSuccessResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
);

Map<String, dynamic> _$ApiSuccessResponseDtoToJson(
  ApiSuccessResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
};
