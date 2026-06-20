import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class SignInWithFacebookUseCase {
  final SessionRepository repository;

  const SignInWithFacebookUseCase(this.repository);

  Future<bool> call() {
    return repository.signInWithFacebook();
  }
}
