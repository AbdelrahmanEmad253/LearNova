/// User profile data from the Supabase `student_profile` table.
class StudentProfile {
  final String userId;
  final String? fullName;
  final String? assignedTrack;

  /// The user's VARK learning style: 'visual', 'auditory', 'readwrite', or 'kinesthetic'.
  final String? learningStyle;

  final int momentumStreak;
  final String? zoneState;
  final int totalXp;

  const StudentProfile({
    required this.userId,
    this.fullName,
    this.assignedTrack,
    this.learningStyle,
    this.momentumStreak = 0,
    this.zoneState,
    this.totalXp = 0,
  });

  /// Returns the effective VARK style, defaulting to 'visual' if not set.
  String get effectiveVarkStyle => learningStyle ?? 'visual';
}
