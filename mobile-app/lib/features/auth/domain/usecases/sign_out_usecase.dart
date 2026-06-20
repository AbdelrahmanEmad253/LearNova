import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class SignOutUseCase {
  final SessionRepository repository;

  const SignOutUseCase(this.repository);

  Future<void> call() {
    return repository.signOut();
  }
}
