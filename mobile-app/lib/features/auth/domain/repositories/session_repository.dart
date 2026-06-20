import 'package:learnova/features/auth/domain/entities/auth_session.dart';

abstract class SessionRepository {
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<bool> signInWithGoogle();

  Future<bool> signInWithFacebook();

  Future<void> signOut();

  Stream<AuthSession?> observeSession();

  AuthSession? currentSession();

  Future<void> resendConfirmationEmail(String email);
}
