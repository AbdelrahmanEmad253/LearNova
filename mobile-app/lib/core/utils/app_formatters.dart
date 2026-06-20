class AppFormatters {
  const AppFormatters._();

  static String toHours(double value) {
    return '${value.toStringAsFixed(2)} hr';
  }

  static String toPercent(double value) {
    return '${(value * 100).toInt()}%';
  }

  static String toClock(Duration value) {
    final int totalSeconds = value.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
