import '../entities/topic_progress_entity.dart';

abstract class ICurriculumRepository {
  /// Stream the topic progress.
  /// ARCH-RULE: student_progress is the SOLE source of truth for the UI.
  Stream<TopicProgress?> watchTopicProgress(String userId, String topicId);
  
  /// Upsert the topic status.
  /// ARCH-RULE: ALWAYS use .upsert() matching on the composite primary key (user_id, topicId).
  Future<void> upsertTopicStatus({
    required String userId,
    required String topicId,
    required TopicStatus status,
  });

  /// Log user engagement telemetry.
  /// ARCH-RULE: content_engagement_logs is a WRITE-ONLY firehose.
  Future<void> logTelemetry(EngagementLog log);

  /// Consume a resource to earn XP.
  /// ARCH-RULE: THE FORBIDDEN WRITE. Invoke a Supabase Edge Function named 'consume-resource'.
  Future<int> consumeResource({
    required String topicId,
    required String resourceType,
  });
}
