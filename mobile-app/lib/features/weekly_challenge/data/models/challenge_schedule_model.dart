import 'package:learnova/features/weekly_challenge/data/models/weekly_challenge_model.dart';

class ChallengeScheduleModel {
  final String id;
  final String userId;
  final String challengeId;
  final String status;
  final DateTime assignedAt;
  final DateTime availableFrom;
  final DateTime expiresAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int currentAttempts;
  final double? bestScore;
  final bool passed;

  // Nested relation
  final WeeklyChallengeModel? challengeDetails;

  const ChallengeScheduleModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.status,
    required this.assignedAt,
    required this.availableFrom,
    required this.expiresAt,
    this.startedAt,
    this.completedAt,
    required this.currentAttempts,
    this.bestScore,
    required this.passed,
    this.challengeDetails,
  });

  factory ChallengeScheduleModel.fromJson(Map<String, dynamic> json) {
    return ChallengeScheduleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String,
      status: json['status'] as String? ?? 'locked',
      assignedAt: DateTime.parse(json['assigned_at']),
      availableFrom: DateTime.parse(json['available_from']),
      expiresAt: DateTime.parse(json['expires_at']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      currentAttempts: json['current_attempts'] as int? ?? 0,
      bestScore: (json['best_score'] as num?)?.toDouble(),
      passed: json['passed'] as bool? ?? false,
      challengeDetails: json['weekly_challenges'] != null 
          ? WeeklyChallengeModel.fromJson(json['weekly_challenges'] as Map<String, dynamic>)
          : null,
    );
  }
}
