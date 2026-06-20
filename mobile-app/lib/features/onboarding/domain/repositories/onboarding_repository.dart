import 'package:learnova/features/onboarding/domain/entities/intro_step.dart';

abstract class OnboardingRepository {
  List<IntroStep> getIntroSteps();
}
