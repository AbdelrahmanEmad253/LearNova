import 'package:equatable/equatable.dart';

enum TopicStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed');

  final String value;
  const TopicStatus(this.value);

  factory TopicStatus.fromString(String val) {
    return TopicStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TopicStatus.notStarted,
    );
  }
}

class TopicProgress extends Equatable {
  final String userId;
  final String topicId;
  final TopicStatus status;
  final String? formatServed;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const TopicProgress({
    required this.userId,
    required this.topicId,
    required this.status,
    this.formatServed,
    this.startedAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        topicId,
        status,
        formatServed,
        startedAt,
        completedAt,
      ];
}

class EngagementLog extends Equatable {
  final String userId;
  final String topicId;
  final String? formatType;
  final int timeSpentSeconds;
  final int? engagementScore;
  final bool? bayesianEligible;
  final DateTime? loggedAt;

  const EngagementLog({
    required this.userId,
    required this.topicId,
    this.formatType,
    required this.timeSpentSeconds,
    this.engagementScore,
    this.bayesianEligible,
    this.loggedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        topicId,
        formatType,
        timeSpentSeconds,
        engagementScore,
        bayesianEligible,
        loggedAt,
      ];
}
