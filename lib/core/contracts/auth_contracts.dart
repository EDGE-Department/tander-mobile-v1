/// Auth domain -- raw backend DTOs.
/// These types mirror exactly what the server sends. Never use them in UI.
/// All consumption goes through mappers -> normalized models.
library;

import 'package:json_annotation/json_annotation.dart';

part 'auth_contracts.g.dart';

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

@JsonSerializable()
class LoginRequestDto {
  const LoginRequestDto({required this.identifier, required this.password});

  factory LoginRequestDto.fromJson(Map<String, Object?> json) =>
      _$LoginRequestDtoFromJson(json);

  final String identifier;
  final String password;

  Map<String, Object?> toJson() => _$LoginRequestDtoToJson(this);
}

@JsonSerializable()
class LoginResponseDataDto {
  const LoginResponseDataDto({
    required this.refreshToken,
    this.userId,
    this.email,
    this.username,
    this.phoneNumber,
    this.registrationPhase,
    this.emailVerified,
    this.idVerified,
    this.profileCompleted,
    this.idVerificationStatus,
    this.profilePhotoUrl,
  });

  factory LoginResponseDataDto.fromJson(Map<String, Object?> json) =>
      _$LoginResponseDataDtoFromJson(json);

  final String refreshToken;
  final Object? userId; // backend sends int, not String
  final String? email;
  final String? username;
  final String? phoneNumber;
  final String? registrationPhase;
  final bool? emailVerified;
  final bool? idVerified;
  final bool? profileCompleted;
  final String? idVerificationStatus;
  final String? profilePhotoUrl;

  Map<String, Object?> toJson() => _$LoginResponseDataDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

@JsonSerializable()
class RegisterRequestDto {
  const RegisterRequestDto({
    required this.password,
    this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.username,
    this.dateOfBirth,
    this.gender,
    this.auditId,
    this.consentTerms,
    this.consentDataPrivacy,
    this.consentVersion,
  }) : assert(
         email != null || phone != null,
         'Either email or phone must be provided',
       );

  factory RegisterRequestDto.fromJson(Map<String, Object?> json) =>
      _$RegisterRequestDtoFromJson(json);

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? username;
  final String password;
  final String? dateOfBirth;
  final String? gender;
  final String? auditId;
  final bool? consentTerms;
  final bool? consentDataPrivacy;
  final String? consentVersion;

  Map<String, Object?> toJson() => _$RegisterRequestDtoToJson(this);
}

@JsonSerializable()
class RegisterResponseDataDto {
  const RegisterResponseDataDto({
    required this.userId,
    required this.email,
    required this.username,
    required this.registrationPhase,
  });

  factory RegisterResponseDataDto.fromJson(Map<String, Object?> json) =>
      _$RegisterResponseDataDtoFromJson(json);

  final String userId;
  final String email;
  final String username;
  final String registrationPhase;

  Map<String, Object?> toJson() => _$RegisterResponseDataDtoToJson(this);
}

@JsonSerializable()
class RegisterResponseDto {
  const RegisterResponseDto({required this.success, required this.data});

  factory RegisterResponseDto.fromJson(Map<String, Object?> json) =>
      _$RegisterResponseDtoFromJson(json);

  final bool success;
  final RegisterResponseDataDto data;

  Map<String, Object?> toJson() => _$RegisterResponseDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Forgot / Reset Password
// ---------------------------------------------------------------------------

@JsonSerializable()
class ForgotPasswordRequestDto {
  const ForgotPasswordRequestDto({this.email, this.phoneNumber});

  factory ForgotPasswordRequestDto.fromJson(Map<String, Object?> json) =>
      _$ForgotPasswordRequestDtoFromJson(json);

  final String? email;
  final String? phoneNumber;

  Map<String, Object?> toJson() => _$ForgotPasswordRequestDtoToJson(this);
}

@JsonSerializable()
class VerifyResetOtpRequestDto {
  const VerifyResetOtpRequestDto({
    required this.code,
    this.email,
    this.phoneNumber,
  });

  factory VerifyResetOtpRequestDto.fromJson(Map<String, Object?> json) =>
      _$VerifyResetOtpRequestDtoFromJson(json);

  final String? email;
  final String? phoneNumber;

  /// 6-digit OTP
  final String code;

  Map<String, Object?> toJson() => _$VerifyResetOtpRequestDtoToJson(this);
}

@JsonSerializable()
class VerifyResetOtpResponseDataDto {
  const VerifyResetOtpResponseDataDto({required this.resetToken});

  factory VerifyResetOtpResponseDataDto.fromJson(Map<String, Object?> json) =>
      _$VerifyResetOtpResponseDataDtoFromJson(json);

  /// One-time UUID token, valid for 5 minutes.
  final String resetToken;

  Map<String, Object?> toJson() => _$VerifyResetOtpResponseDataDtoToJson(this);
}

@JsonSerializable()
class VerifyResetOtpResponseDto {
  const VerifyResetOtpResponseDto({
    required this.success,
    required this.data,
    this.message,
  });

  factory VerifyResetOtpResponseDto.fromJson(Map<String, Object?> json) =>
      _$VerifyResetOtpResponseDtoFromJson(json);

  final bool success;
  final String? message;
  final VerifyResetOtpResponseDataDto data;

  Map<String, Object?> toJson() => _$VerifyResetOtpResponseDtoToJson(this);
}

@JsonSerializable()
class ResetPasswordRequestDto {
  const ResetPasswordRequestDto({
    required this.newPassword,
    required this.resetToken,
    this.email,
    this.phoneNumber,
  });

  factory ResetPasswordRequestDto.fromJson(Map<String, Object?> json) =>
      _$ResetPasswordRequestDtoFromJson(json);

  final String? email;
  final String? phoneNumber;
  final String newPassword;

  /// UUID from /verify-reset-otp response.
  final String resetToken;

  Map<String, Object?> toJson() => _$ResetPasswordRequestDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Email verification
// ---------------------------------------------------------------------------

@JsonSerializable()
class VerifyEmailRequestDto {
  const VerifyEmailRequestDto({required this.token});

  factory VerifyEmailRequestDto.fromJson(Map<String, Object?> json) =>
      _$VerifyEmailRequestDtoFromJson(json);

  final String token;

  Map<String, Object?> toJson() => _$VerifyEmailRequestDtoToJson(this);
}

@JsonSerializable()
class ResendVerificationRequestDto {
  const ResendVerificationRequestDto({required this.email});

  factory ResendVerificationRequestDto.fromJson(Map<String, Object?> json) =>
      _$ResendVerificationRequestDtoFromJson(json);

  final String email;

  Map<String, Object?> toJson() => _$ResendVerificationRequestDtoToJson(this);
}

// ---------------------------------------------------------------------------
// Generic responses
// ---------------------------------------------------------------------------

@JsonSerializable()
class ApiSuccessResponseDto {
  const ApiSuccessResponseDto({required this.success, this.message});

  factory ApiSuccessResponseDto.fromJson(Map<String, Object?> json) =>
      _$ApiSuccessResponseDtoFromJson(json);

  final bool success;
  final String? message;

  Map<String, Object?> toJson() => _$ApiSuccessResponseDtoToJson(this);
}
