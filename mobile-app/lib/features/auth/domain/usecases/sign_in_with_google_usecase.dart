import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class SignInWithGoogleUseCase {
  final SessionRepository repository;

  const SignInWithGoogleUseCase(this.repository);

  Future<bool> call() {
    return repository.signInWithGoogle();
  }
}
