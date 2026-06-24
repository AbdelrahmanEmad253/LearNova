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
import 'package:learnova/features/auth/data/models/student_profile_model.dart';
import 'package:entrig/entrig.dart';

import 'package:learnova/features/content/presentation/controllers/mitchy_chat_controller.dart';
import 'package:learnova/features/notifications/presentation/providers/notifications_providers.dart';

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

final authSessionStreamProvider = StreamProvider<AuthSession?>((ref) async* {
  final stream = ref.watch(observeSessionUseCaseProvider).call();
  
  await for (final session in stream) {
    if (session != null) {
      // Register device for push notifications when user is logged in
      Entrig.register(userId: session.userId);
    } else {
      // Unregister when logged out
      Entrig.unregister();
    }
    yield session;
  }
});

final currentSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(getCurrentSessionUseCaseProvider).call();
});

final studentProfileProvider = StreamProvider<StudentProfile?>((ref) async* {
  final session = ref.watch(authSessionStreamProvider).value;
  if (session == null) {
    yield null;
    return;
  }

  final client = ref.watch(supabaseClientProvider);
  final localDS = ref.watch(studentProfileLocalDataSourceProvider);

  // Fallback to local cache initially while stream connects
  final cached = await localDS.getCachedProfile();
  if (cached != null) yield cached;

  final stream = client
      .from('student_profiles')
      .stream(primaryKey: ['user_id'])
      .eq('user_id', session.userId)
      .map((list) {
        if (list.isEmpty) return null;
        return StudentProfileModel.fromJson(list.first);
      });

  await for (final profile in stream) {
    if (profile != null) {
      await localDS.cacheProfile(profile);
    }
    yield profile;
  }
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
    
    // Clear the notification cache from SharedPreferences
    await ref.read(notificationsCacheProvider).clear();
    
    // Invalidate global providers so they don't leak state into the next user session
    ref.invalidate(mitchyChatControllerProvider);
    ref.invalidate(notificationsDataProvider);
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
