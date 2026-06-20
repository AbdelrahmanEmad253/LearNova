import 'package:learnova/features/onboarding/domain/entities/intro_step.dart';

class IntroStepModel {
  final String title;
  final String description;
  final String iconPath;
  final String? lightIconPath;
  final String topWavePath;
  final String bottomWavePath;
  final bool isSvg;

  const IntroStepModel({
    required this.title,
    required this.description,
    required this.iconPath,
    this.lightIconPath,
    required this.topWavePath,
    required this.bottomWavePath,
    required this.isSvg,
  });

  IntroStep toEntity() {
    return IntroStep(
      title: title,
      description: description,
      iconPath: iconPath,
      lightIconPath: lightIconPath,
      topWavePath: topWavePath,
      bottomWavePath: bottomWavePath,
      isSvg: isSvg,
    );
  }
}
