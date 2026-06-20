import 'package:learnova/features/auth/domain/entities/auth_session.dart';
import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class GetCurrentSessionUseCase {
  final SessionRepository repository;

  const GetCurrentSessionUseCase(this.repository);

  AuthSession? call() {
    return repository.currentSession();
  }
}
