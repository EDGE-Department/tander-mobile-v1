import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';

/// Terminates the current authentication session.
final class SignOutUseCase {
  const SignOutUseCase({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  /// Delegates to [AuthRepository.signOut] to clear tokens and session state.
  Future<Result<void>> execute() {
    return _repository.signOut();
  }
}
