import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class ResendConfirmationEmailUseCase {
  final SessionRepository repository;

  const ResendConfirmationEmailUseCase(this.repository);

  Future<void> call(String email) {
    return repository.resendConfirmationEmail(email);
  }
}
