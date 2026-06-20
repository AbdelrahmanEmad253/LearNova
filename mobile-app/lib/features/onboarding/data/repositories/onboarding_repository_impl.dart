import 'package:learnova/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:learnova/features/onboarding/domain/entities/intro_step.dart';
import 'package:learnova/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource localDataSource;

  const OnboardingRepositoryImpl(this.localDataSource);

  @override
  List<IntroStep> getIntroSteps() {
    return localDataSource
        .getIntroSteps()
        .map((stepModel) => stepModel.toEntity())
        .toList();
  }
}
