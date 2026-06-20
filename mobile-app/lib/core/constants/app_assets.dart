class AppAssets {
  static const String spaceBackground = 'assets/SpaceBackground.png';

  // Map
  static const String mapScrollTop = 'assets/map/scrolltop.svg';
  static const String mapFixedTop = 'assets/map/fixedtop.svg';
  static const String mapTop = 'assets/map/top.svg';
  static const String mapModuleBottom = 'assets/map/modulebottom.svg';
  static const String mapBackground = 'assets/map/map.png';
  static const String mapModuleShape = 'assets/map/module.svg';

  // Quests
  static const String questChestPng = 'assets/quests/chest.png';
  static const String questSectionMarker = 'assets/quests/Subtract.svg';

  // Avatar
  static const String avatarMitchy = 'assets/avatar/Mitchy.png';
  static const String avatar1 = 'assets/avatar/avatar1.svg';
  static const String avatar2 = 'assets/avatar/avatar2.svg';
  static const String avatar3 = 'assets/avatar/avatar3.svg';
  static const String avatar4 = 'assets/avatar/avatar4.svg';

  // Content/Star
  static const String contentWaveBottom =
      'assets/star/figma_audio_28283/bg_wave_bottom.svg';
  static const String audioDisc = 'assets/star/playsound.png';
  static const String audioPreview = 'assets/star/sound.png';
  static const String starIcon = 'assets/star/star.svg';
  static const String hexFrame = 'assets/star/hex.svg';
  static const String onboardingStartTest = 'assets/star/starttest.svg';
  static const String onboardingStartTestLight = 'assets/star/asstestL.svg';
  static const String onboardingStartGroup = 'assets/star/startgroup.svg';
  static const String onboardingStartGroupLight = 'assets/star/prospectsL.svg';
  static const String onboardingRankGroup = 'assets/star/rankgroup.png';
  static const String onboardingRankGroupLight = 'assets/star/gameifiedL.svg';

  // Profile
  static const String profileTop = 'assets/profile/profiletop.svg';
  static const String profilePic = 'assets/profile/profilePic.svg';
  static const String profileBadge = 'assets/profile/badge.svg';
  static const String profileSliFox = 'assets/profile/sli-fox.png';
  static const String perkOwl = 'assets/profile/owl_of_wisdom.png';
  static const String perkFox = 'assets/profile/sli_fox_rx50.png';

  // Generic auth wave assets
  static const String authTop = 'assets/top.svg';
  static const String authBottomHigh = 'assets/bottomhigh.svg';
  static const String wavesTop = 'assets/waves/top.svg';
  static const String wavesTop2 = 'assets/waves/top2.svg';
  static const String wavesPrimeTop = 'assets/waves/primeTop.svg';
  static const String wavesPrimeTop2 = 'assets/waves/primeTop2.svg';
  static const String wavesBottom = 'assets/waves/bottom.svg';
  static const String wavesBottom2 = 'assets/waves/bottom2.svg';
  static const String wavesPrimeBottom = 'assets/waves/primebottom.svg';
  static const String wavesPrimeBottom2 = 'assets/waves/primebottom2.svg';

  // Welcoming waves
  static const String welcomingTop1 = 'assets/waves/welcoming_waves/top1.svg';
  static const String welcomingTop2 = 'assets/waves/welcoming_waves/top2.svg';
  static const String welcomingTop3 = 'assets/waves/welcoming_waves/top3.svg';
  static const String welcomingTop4 = 'assets/waves/welcoming_waves/top4.svg';
  static const String welcomingBottom1 =
      'assets/waves/welcoming_waves/bottom1.svg';
  static const String welcomingBottom2 =
      'assets/waves/welcoming_waves/bottom2.svg';
  static const String welcomingBottom3 =
      'assets/waves/welcoming_waves/bottom3.svg';
  static const String welcomingBottom4 =
      'assets/waves/welcoming_waves/bottom4.svg';

  // Test flow assets
  static const String testStartTop = 'assets/waves/test/teststartop.svg';
  static const String testStartBottom = 'assets/waves/test/teststartbot.svg';
  static const String testMiniBottom = 'assets/waves/test/minibot.svg';
  static const String testSmallCircle = 'assets/waves/test/smallcircle.png';
  static const String testCircleUp = 'assets/waves/test/circleup.png';
  static const String testCircleDown = 'assets/waves/test/circlebown.png';
  static const String testIconMind = 'assets/waves/test/icons/mind.svg';
  static const String testIconSoft = 'assets/waves/test/icons/soft.svg';
  static const String testIconPersonal = 'assets/waves/test/icons/personal.svg';
  static const String testIconLearn = 'assets/waves/test/icons/learn.svg';
  static const String testIconCareer = 'assets/waves/test/icons/career.svg';
  static const String testCognTop = 'assets/waves/test/Cogntop.svg';
  static const String testCognBg = 'assets/waves/test/cogntestbg.png';
  static const String testSoftTop = 'assets/waves/test/softtop.svg';
  static const String testSoftBg = 'assets/waves/test/softestbg.png';
  static const String testPersonalTop = 'assets/waves/test/personaltop.svg';
  static const String testPersonalBg = 'assets/waves/test/persontestbg.png';
  static const String testLearnTop = 'assets/waves/test/learntop.svg';
  static const String testLearnBg = 'assets/waves/test/learntestbg.png';
  static const String testCareerTop = 'assets/waves/test/carerrtop.svg';
  static const String testCareerBg = 'assets/waves/test/carrertestbg.png';

  static String mapLevel(int levelNumber) => 'assets/map/levelbutton.png';

  /// Cycles level artwork across lev1 → lev2 → lev3 for levels 4+.
  static int _normalizedMapLevel(int levelNumber) {
    return ((levelNumber - 1) % 3) + 1;
  }

  /// Level 1–2: left island. Level 3: rlisland for both sides.
  static String islandLeft(int levelNumber) {
    switch (_normalizedMapLevel(levelNumber)) {
      case 3:
        return 'assets/map/levelslands/lev3/rlisland.png';
      case 2:
        return 'assets/map/levelslands/lev2/leftisland.png';
      case 1:
      default:
        return 'assets/map/levelslands/lev1/leftisland.png';
    }
  }

  /// Level 1–2: right island. Level 3: rlisland for both sides.
  static String islandRight(int levelNumber) {
    switch (_normalizedMapLevel(levelNumber)) {
      case 3:
        return 'assets/map/levelslands/lev3/rlisland.png';
      case 2:
        return 'assets/map/levelslands/lev2/rightisland.png';
      case 1:
      default:
        return 'assets/map/levelslands/lev1/rightisland.png';
    }
  }

  static String islandExam(int levelNumber) {
    switch (_normalizedMapLevel(levelNumber)) {
      case 3:
        return 'assets/map/levelslands/lev3/examisland.png';
      case 2:
        return 'assets/map/levelslands/lev2/examsland.png';
      case 1:
      default:
        return 'assets/map/levelslands/lev1/examisland.png';
    }
  }

  /// Generic fallbacks under assets/map/islands/ when per-level assets fail to load.
  static String islandLeftFallback() => 'assets/map/islands/leftisland.png';

  static String islandRightFallback() => 'assets/map/islands/rightisland.png';

  static String islandExamFallback() => 'assets/map/islands/examisland.png';

  static String fallbackForIslandAsset(String primaryAsset) {
    if (primaryAsset.contains('rlisland')) {
      return 'assets/map/islands/rlisland.png';
    }
    if (primaryAsset.contains('examsland') || primaryAsset.contains('examisland')) {
      return islandExamFallback();
    }
    if (primaryAsset.contains('rightisland')) {
      return islandRightFallback();
    }
    return islandLeftFallback();
  }

  static String avatarByFileName(String fileName) => 'assets/avatar/$fileName';

  static String preExamBottomWaveByLevel(int levelNumber) {
    final normalized = ((levelNumber - 1) % 3) + 1;
    switch (normalized) {
      case 1:
        return welcomingBottom1;
      case 2:
        return welcomingBottom2;
      case 3:
      default:
        return welcomingBottom3;
    }
  }

  const AppAssets._();
}
