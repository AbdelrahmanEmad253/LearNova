import 'package:learnova/features/onboarding/data/models/intro_step_model.dart';
import 'package:learnova/core/constants/app_assets.dart';

class OnboardingLocalDataSource {
  const OnboardingLocalDataSource();

  List<IntroStepModel> getIntroSteps() {
    return const [
      IntroStepModel(
        title: 'Assessment Tests',
        description:
            'To get started, you\'re gonna have to get through 5 essential cumulative tests for evaluating your character AND deciding the best CS track applicable for you',
        iconPath: AppAssets.onboardingStartTest,
        lightIconPath: AppAssets.onboardingStartTestLight,
        topWavePath: AppAssets.welcomingTop2,
        bottomWavePath: AppAssets.welcomingBottom2,
        isSvg: true,
      ),
      IntroStepModel(
        title: 'Explore your\nhidden prospects',
        description:
            'Follow a structured path that helps you learn, grow, and progress in the technical field—guided by the track that best aligns with your natural strengths',
        iconPath: AppAssets.onboardingStartGroup,
        lightIconPath: AppAssets.onboardingStartGroupLight,
        topWavePath: AppAssets.welcomingTop3,
        bottomWavePath: AppAssets.welcomingBottom3,
        isSvg: true,
      ),
      IntroStepModel(
        title: 'Gamified Learning',
        description:
            'Studying was never more fun without adding some challenging environment. Beat levels, Promote your rank, Unlock Perks and much more!',
        iconPath: AppAssets.onboardingRankGroup,
        lightIconPath: AppAssets.onboardingRankGroup, // Revert to PNG for reliability
        topWavePath: AppAssets.welcomingTop4,
        bottomWavePath: AppAssets.welcomingBottom4,
        isSvg: false,
      ),
    ];
  }
}
