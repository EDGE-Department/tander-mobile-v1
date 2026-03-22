import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';

/// Authenticates a user with email and password credentials.
final class SignInUseCase {
  const SignInUseCase({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  /// Delegates to [AuthRepository.signIn] and returns the authenticated session.
  Future<Result<AuthSession>> execute({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
