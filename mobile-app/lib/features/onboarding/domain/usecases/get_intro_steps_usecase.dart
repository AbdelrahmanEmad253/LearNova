import 'package:learnova/features/onboarding/domain/entities/intro_step.dart';
import 'package:learnova/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetIntroStepsUseCase {
  final OnboardingRepository repository;

  const GetIntroStepsUseCase(this.repository);

  List<IntroStep> call() {
    return repository.getIntroSteps();
  }
}
