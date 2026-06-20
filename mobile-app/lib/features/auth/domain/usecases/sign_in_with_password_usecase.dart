import 'package:learnova/features/auth/domain/entities/auth_session.dart';
import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class SignInWithPasswordUseCase {
  final SessionRepository repository;

  const SignInWithPasswordUseCase(this.repository);

  Future<AuthSession> call({
    required String email,
    required String password,
  }) {
    return repository.signInWithPassword(email: email, password: password);
  }
}
