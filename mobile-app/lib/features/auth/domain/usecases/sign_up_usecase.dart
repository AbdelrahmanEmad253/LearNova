import 'package:learnova/features/auth/domain/entities/auth_session.dart';
import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class SignUpUseCase {
  final SessionRepository repository;

  const SignUpUseCase(this.repository);

  Future<AuthSession> call({
    required String email,
    required String password,
    required String username,
  }) {
    return repository.signUp(
      email: email,
      password: password,
      username: username,
    );
  }
}
