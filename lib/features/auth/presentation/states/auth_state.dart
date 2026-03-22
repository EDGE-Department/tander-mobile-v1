import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

/// Sealed state hierarchy for the auth UI.
///
/// Using a sealed class guarantees exhaustive `switch` — the compiler
/// will error if a new subclass is added without updating every consumer.
sealed class AuthState {
  const AuthState();
}

/// Initial state before any auth check has run.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An auth operation (bootstrap, sign-in, register) is in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is fully authenticated and has completed onboarding.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.session});

  final AuthSession session;
}

/// No valid session exists — the user must sign in or register.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed with a typed exception.
final class AuthError extends AuthState {
  const AuthError({required this.exception});

  final AppException exception;
}

/// The user is authenticated but has not finished onboarding.
final class AuthOnboarding extends AuthState {
  const AuthOnboarding({required this.phase, required this.session});

  final RegistrationPhase phase;
  final AuthSession session;
}
