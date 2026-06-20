import 'package:learnova/features/auth/domain/entities/student_profile.dart';

class StudentProfileModel extends StudentProfile {
  const StudentProfileModel({
    required super.userId,
    super.fullName,
    super.assignedTrack,
    super.learningStyle,
    super.momentumStreak,
    super.zoneState,
    super.totalXp,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      assignedTrack: json['assigned_track']?.toString(),
      learningStyle: json['learning_style']?.toString(),
      momentumStreak: (json['momentum_streak'] as int?) ?? 0,
      zoneState: json['zone_state']?.toString(),
      totalXp: (json['xp_total'] as int?) ?? (json['total_xp'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'assigned_track': assignedTrack,
        'learning_style': learningStyle,
        'momentum_streak': momentumStreak,
        'zone_state': zoneState,
        'xp_total': totalXp,
      };
}
