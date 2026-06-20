import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/auth/data/datasources/avatar_local_data_source.dart';
import 'package:learnova/features/auth/data/repositories/avatar_repository_impl.dart';
import 'package:learnova/features/auth/domain/entities/avatar_option.dart';
import 'package:learnova/features/auth/domain/usecases/get_avatar_options_usecase.dart';
import 'package:learnova/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:learnova/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:learnova/features/onboarding/domain/entities/intro_step.dart';
import 'package:learnova/features/onboarding/domain/usecases/get_intro_steps_usecase.dart';

final avatarOptionsProvider = Provider<List<AvatarOption>>((ref) {
  final useCase = GetAvatarOptionsUseCase(
    const AvatarRepositoryImpl(AvatarLocalDataSource()),
  );
  return useCase();
});

final introStepsProvider = Provider<List<IntroStep>>((ref) {
  final useCase = GetIntroStepsUseCase(
    const OnboardingRepositoryImpl(OnboardingLocalDataSource()),
  );
  return useCase();
});
