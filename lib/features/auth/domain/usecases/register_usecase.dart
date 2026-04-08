import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';

/// Creates a new user account and returns the initial session.
final class RegisterUseCase {
  const RegisterUseCase({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  /// Delegates to [AuthRepository.register] with the provided registration details.
  Future<Result<AuthSession>> execute({
    String? email,
    String? phone,
    required String password,
    required String auditId,
  }) {
    return _repository.register(
      email: email,
      phone: phone,
      password: password,
      auditId: auditId,
    );
  }
}
