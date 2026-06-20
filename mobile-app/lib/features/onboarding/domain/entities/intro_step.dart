class IntroStep {
  final String title;
  final String description;
  final String iconPath;
  final String? lightIconPath;
  final String topWavePath;
  final String bottomWavePath;
  final bool isSvg;

  const IntroStep({
    required this.title,
    required this.description,
    required this.iconPath,
    this.lightIconPath,
    required this.topWavePath,
    required this.bottomWavePath,
    required this.isSvg,
  });
}
