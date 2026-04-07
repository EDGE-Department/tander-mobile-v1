sealed class AppException implements Exception {
  const AppException({required this.message, this.stackTrace, this.code});

  final String message;
  final StackTrace? stackTrace;
  final String? code;

  String get userMessage;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'Unable to connect. Please check your internet connection and try again.';
}

final class ServerException extends AppException {
  const ServerException({
    required super.message,
    required this.statusCode,
    super.stackTrace,
    super.code,
  });

  final int statusCode;

  @override
  String get userMessage =>
      'Something went wrong on our end. Please try again later.';
}

final class AuthException extends AppException {
  const AuthException({
    required super.message,
    required this.reason,
    super.stackTrace,
    super.code,
  });

  final AuthFailureReason reason;

  @override
  String get userMessage => switch (reason) {
        AuthFailureReason.tokenExpired =>
          'Your session has expired. Please sign in again.',
        AuthFailureReason.forbidden =>
          'You do not have permission to perform this action.',
        AuthFailureReason.invalidCredentials =>
          'Invalid email or password. Please try again.',
      };
}

enum AuthFailureReason { tokenExpired, forbidden, invalidCredentials }

final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    required this.fieldErrors,
    super.stackTrace,
    super.code,
  });

  final Map<String, List<String>> fieldErrors;

  @override
  String get userMessage => message.isNotEmpty
      ? message
      : 'Please correct the highlighted fields and try again.';
}

final class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'A local storage error occurred. Please restart the app.';
}

final class RateLimitException extends AppException {
  const RateLimitException({
    required super.message,
    required this.retryAfterSeconds,
    super.stackTrace,
    super.code,
  });

  final int retryAfterSeconds;

  @override
  String get userMessage =>
      'Too many requests. Please wait $retryAfterSeconds seconds and try again.';
}

final class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.stackTrace,
    super.code,
  });

  @override
  String get userMessage => 'The requested item could not be found.';
}

final class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.stackTrace,
    super.code,
  });

  @override
  String get userMessage => message.isNotEmpty
      ? message
      : 'A conflict occurred. You may already have an active session on another device.';
}

final class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.stackTrace,
    super.code,
  });

  @override
  String get userMessage => 'An unexpected error occurred. Please try again.';
}
