import 'package:learnova/features/auth/domain/entities/auth_session.dart';
import 'package:learnova/features/auth/domain/repositories/session_repository.dart';

class ObserveSessionUseCase {
  final SessionRepository repository;

  const ObserveSessionUseCase(this.repository);

  Stream<AuthSession?> call() {
    return repository.observeSession();
  }
}
