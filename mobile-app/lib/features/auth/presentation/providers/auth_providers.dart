import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/auth/data/datasources/session_local_data_source.dart';
import 'package:learnova/features/auth/data/datasources/session_remote_data_source.dart';
import 'package:learnova/features/auth/data/repositories/session_repository_impl.dart';
import 'package:learnova/features/auth/domain/entities/auth_session.dart';
import 'package:learnova/features/auth/domain/repositories/session_repository.dart';
import 'package:learnova/features/auth/domain/usecases/get_current_session_usecase.dart';
import 'package:learnova/features/auth/domain/usecases/observe_session_usecase.dart';
import 'package:learnova/features/auth/domain/usecases/sign_in_with_password_usecase.dart';
import 'package:learnova/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:learnova/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:learnova/features/auth/domain/usecases/sign_in_with_facebook_usecase.dart';
import 'package:learnova/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:learnova/features/auth/domain/usecases/resend_confirmation_email_usecase.dart';

import 'package:learnova/features/auth/data/datasources/student_profile_local_data_source.dart';
import 'package:learnova/features/auth/data/datasources/student_profile_remote_data_source.dart';
import 'package:learnova/features/auth/domain/entities/student_profile.dart';

// ── Data Sources ──

final sessionRemoteDataSourceProvider =
    Provider<SessionRemoteDataSource>((ref) {
  return SessionRemoteDataSource(ref.watch(supabaseClientProvider));
});

final sessionLocalDataSourceProvider = Provider<SessionLocalDataSource>((ref) {
  return SessionLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final studentProfileLocalDataSourceProvider =
    Provider<StudentProfileLocalDataSource>((ref) {
  return StudentProfileLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final studentProfileRemoteDataSourceProvider =
    Provider<StudentProfileRemoteDataSource>((ref) {
  return StudentProfileRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ── Repository ──

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(
    remoteDataSource: ref.watch(sessionRemoteDataSourceProvider),
    localDataSource: ref.watch(sessionLocalDataSourceProvider),
  );
});

// ── Use Cases ──

final signInWithPasswordUseCaseProvider =
    Provider<SignInWithPasswordUseCase>((ref) {
  return SignInWithPasswordUseCase(ref.watch(sessionRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(sessionRepositoryProvider));
});

final signInWithGoogleUseCaseProvider =
    Provider<SignInWithGoogleUseCase>((ref) {
  return SignInWithGoogleUseCase(ref.watch(sessionRepositoryProvider));
});

final signInWithFacebookUseCaseProvider =
    Provider<SignInWithFacebookUseCase>((ref) {
  return SignInWithFacebookUseCase(ref.watch(sessionRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(sessionRepositoryProvider));
});

final resendConfirmationEmailUseCaseProvider =
    Provider<ResendConfirmationEmailUseCase>((ref) {
  return ResendConfirmationEmailUseCase(ref.watch(sessionRepositoryProvider));
});

final observeSessionUseCaseProvider = Provider<ObserveSessionUseCase>((ref) {
  return ObserveSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final getCurrentSessionUseCaseProvider =
    Provider<GetCurrentSessionUseCase>((ref) {
  return GetCurrentSessionUseCase(ref.watch(sessionRepositoryProvider));
});

// ── Reactive Session State ──

final authSessionStreamProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(observeSessionUseCaseProvider).call();
});

final currentSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(getCurrentSessionUseCaseProvider).call();
});

final studentProfileProvider = FutureProvider<StudentProfile?>((ref) async {
  // Regenerate when auth state changes
  ref.watch(authSessionStreamProvider);

  final remoteDS = ref.watch(studentProfileRemoteDataSourceProvider);
  final localDS = ref.watch(studentProfileLocalDataSourceProvider);

  try {
    final profile = await remoteDS.fetchProfile();
    if (profile != null) {
      await localDS.cacheProfile(profile);
      return profile;
    }
  } catch (_) {}

  // Fallback to local cache if remote fails or returns null
  return localDS.getCachedProfile();
});

// ── Auth Controller (actions) ──

class AuthController extends AsyncNotifier<void> {
  late final SignInWithPasswordUseCase _signInWithPasswordUseCase =
      ref.read(signInWithPasswordUseCaseProvider);
  late final SignUpUseCase _signUpUseCase = ref.read(signUpUseCaseProvider);
  late final SignInWithGoogleUseCase _signInWithGoogleUseCase =
      ref.read(signInWithGoogleUseCaseProvider);
  late final SignInWithFacebookUseCase _signInWithFacebookUseCase =
      ref.read(signInWithFacebookUseCaseProvider);
  late final SignOutUseCase _signOutUseCase = ref.read(signOutUseCaseProvider);
  late final ResendConfirmationEmailUseCase _resendConfirmationEmailUseCase =
      ref.read(resendConfirmationEmailUseCaseProvider);

  @override
  FutureOr<void> build() {}

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () async {
        await _signInWithPasswordUseCase(email: email, password: password);
      },
    );
    state = result;
    if (result.hasError) throw result.error!;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () async {
        await _signUpUseCase(
          email: email,
          password: password,
          username: username,
        );
      },
    );
    state = result;
    if (result.hasError) throw result.error!;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_signInWithGoogleUseCase.call);
    state = result;
    if (result.hasError) throw result.error!;
  }

  Future<void> signInWithFacebook() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_signInWithFacebookUseCase.call);
    state = result;
    if (result.hasError) throw result.error!;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_signOutUseCase.call);
  }

  Future<void> resendConfirmationEmail(String email) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _resendConfirmationEmailUseCase(email),
    );
    state = result;
    if (result.hasError) throw result.error!;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
