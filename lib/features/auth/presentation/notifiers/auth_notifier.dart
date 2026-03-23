import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages auth state transitions for the entire application.
///
/// Delegates all IO to [AuthRepository] and translates [Result] outcomes
/// into the sealed [AuthState] hierarchy so the UI can do exhaustive switches.
final class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    return const AuthInitial();
  }

  // -------------------------------------------------------------------------
  // Bootstrap — cold-start session restore
  // -------------------------------------------------------------------------

  /// Attempts to restore a persisted session on app startup.
  ///
  /// On success, transitions to [AuthAuthenticated] or [AuthOnboarding]
  /// depending on the user's registration phase.
  /// On failure (or no stored tokens), transitions to [AuthUnauthenticated].
  Future<void> bootstrap() async {
    state = const AuthLoading();

    final bootstrapResult = await _repository.bootstrapSession();
    final isRestored = bootstrapResult.valueOrNull ?? false;

    if (!isRestored) {
      state = const AuthUnauthenticated();
      return;
    }

    await _syncSessionFromServer();
  }

  // -------------------------------------------------------------------------
  // Sign in
  // -------------------------------------------------------------------------

  /// Authenticates with [email] and [password].
  ///
  /// Transitions to [AuthAuthenticated] or [AuthOnboarding] on success,
  /// [AuthError] on failure.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    final signInResult = await _repository.signIn(
      email: email,
      password: password,
    );

    signInResult.when(
      success: _transitionToSessionState,
      failure: (exception) => state = AuthError(exception: exception),
    );
  }

  // -------------------------------------------------------------------------
  // Register
  // -------------------------------------------------------------------------

  /// Creates a new account and transitions to [AuthOnboarding].
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    state = const AuthLoading();

    final registerResult = await _repository.register(
      email: email,
      password: password,
      username: username,
      firstName: firstName,
      lastName: lastName,
    );

    registerResult.when(
      success: (session) => state = AuthOnboarding(
        phase: session.registrationPhase,
        session: session,
      ),
      failure: (exception) => state = AuthError(exception: exception),
    );
  }

  // -------------------------------------------------------------------------
  // Sign out
  // -------------------------------------------------------------------------

  /// Terminates the session and transitions to [AuthUnauthenticated].
  ///
  /// Even if the server call fails, the local session is cleared so the
  /// user is always returned to the unauthenticated state.
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthUnauthenticated();
  }

  // -------------------------------------------------------------------------
  // Refresh session — after onboarding step or phase change
  // -------------------------------------------------------------------------

  /// Forces transition to [AuthUnauthenticated], used when bootstrap times out.
  void forceUnauthenticated() {
    state = const AuthUnauthenticated();
  }

  /// Re-fetches the current user from the server and updates state.
  ///
  /// Useful after completing an onboarding step to check whether the
  /// user has advanced to the next phase or reached [AuthAuthenticated].
  Future<void> refreshSession() async {
    await _syncSessionFromServer();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Fetches the current user from the server and transitions state
  /// based on the registration phase.
  Future<void> _syncSessionFromServer() async {
    final userResult = await _repository.getCurrentUser();

    userResult.when(
      success: _transitionToSessionState,
      failure: (exception) => state = AuthError(exception: exception),
    );
  }

  /// Determines whether the session represents a fully onboarded user
  /// or one still in the onboarding flow, and sets state accordingly.
  void _transitionToSessionState(AuthSession session) {
    if (session.isOnboardingComplete) {
      state = AuthAuthenticated(session: session);
    } else {
      state = AuthOnboarding(
        phase: session.registrationPhase,
        session: session,
      );
    }
  }
}
