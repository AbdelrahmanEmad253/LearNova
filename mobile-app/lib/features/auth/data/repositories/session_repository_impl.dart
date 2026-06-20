import 'package:learnova/features/auth/data/datasources/session_local_data_source.dart';
import 'package:learnova/features/auth/data/datasources/session_remote_data_source.dart';
import 'package:learnova/features/auth/domain/entities/auth_session.dart';
import 'package:learnova/features/auth/domain/repositories/session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource remoteDataSource;
  final SessionLocalDataSource localDataSource;

  const SessionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  AuthSession? currentSession() {
    final session = remoteDataSource.currentSession();
    final user = session?.user;
    if (user == null) {
      return null;
    }

    return AuthSession(userId: user.id, email: user.email);
  }

  @override
  Stream<AuthSession?> observeSession() {
    return remoteDataSource.observeAuthChanges().asyncMap((authState) async {
      final session = authState.session;
      final user = session?.user;

      if (user == null) {
        await localDataSource.clearSessionMeta();
        return null;
      }

      await localDataSource.saveSessionMeta(
        userId: user.id,
        email: user.email,
      );

      return AuthSession(
        userId: user.id,
        email: user.email,
      );
    });
  }

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final authResponse = await remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) {
      throw AuthException('Login failed: no user returned from server.');
    }

    await localDataSource.saveSessionMeta(
      userId: user.id,
      email: user.email,
    );

    return AuthSession(
      userId: user.id,
      email: user.email,
    );
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final authResponse = await remoteDataSource.signUp(
      email: email,
      password: password,
      username: username,
    );

    final user = authResponse.user;
    if (user == null) {
      throw AuthException('Sign-up failed: no user returned from server.');
    }

    await localDataSource.saveSessionMeta(
      userId: user.id,
      email: user.email,
    );

    return AuthSession(
      userId: user.id,
      email: user.email,
    );
  }

  @override
  Future<bool> signInWithGoogle() {
    return remoteDataSource.signInWithGoogle();
  }

  @override
  Future<bool> signInWithFacebook() {
    return remoteDataSource.signInWithFacebook();
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
    await localDataSource.clearSessionMeta();
  }

  @override
  Future<void> resendConfirmationEmail(String email) {
    return remoteDataSource.resendConfirmationEmail(email);
  }
}
