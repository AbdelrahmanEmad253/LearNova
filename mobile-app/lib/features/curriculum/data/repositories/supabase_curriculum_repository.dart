
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/topic_progress_entity.dart';
import '../../domain/repositories/i_curriculum_repository.dart';

class SupabaseCurriculumRepository implements ICurriculumRepository {
  final SupabaseClient _client;

  SupabaseCurriculumRepository(this._client);

  @override
  Stream<TopicProgress?> watchTopicProgress(String userId, String topicId) {
    // ARCH-RULE: student_progress is the SOLE source of truth for the UI.
    return _client
        .from('student_progress')
        .stream(primaryKey: ['user_id', 'topic_id'])
        .eq('user_id', userId)
        .map((events) {
          try {
            final data = events.firstWhere((e) => e['topic_id'] == topicId);
            return TopicProgress(
              userId: data['user_id'] as String,
              topicId: data['topic_id'] as String,
              status: TopicStatus.fromString(data['status'] as String? ?? 'not_started'),
              formatServed: data['format_served'] as String?,
              startedAt: data['started_at'] != null ? DateTime.parse(data['started_at'] as String) : null,
              completedAt: data['completed_at'] != null ? DateTime.parse(data['completed_at'] as String) : null,
            );
          } catch (e) {
            return null;
          }
        });
  }

  @override
  Future<void> upsertTopicStatus({
    required String userId,
    required String topicId,
    required TopicStatus status,
  }) async {
    // ARCH-RULE: ALWAYS use .upsert() matching on the composite primary key (user_id, topic_id).
    final updateData = <String, dynamic>{
      'user_id': userId,
      'topic_id': topicId,
      'status': status.value,
    };

    if (status == TopicStatus.inProgress) {
      updateData['started_at'] = DateTime.now().toUtc().toIso8601String();
    } else if (status == TopicStatus.completed) {
      updateData['completed_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await _client.from('student_progress').upsert(updateData);
  }

  @override
  Future<void> logTelemetry(EngagementLog log) async {
    // ARCH-RULE: WRITE-ONLY firehose. Forbidden from writing any .select() queries for this table.
    final data = <String, dynamic>{
      'user_id': log.userId,
      'topic_id': log.topicId,
      if (log.formatType != null) 'format_type': switch (log.formatType?.toLowerCase()) {
        'video' => 'Visual',
        'audio' => 'Auditory',
        'text' => 'Textual',
        'visual' => 'Visual',
        'auditory' => 'Auditory',
        'textual' => 'Textual',
        _ => log.formatType,
      },
      'time_spent_seconds': log.timeSpentSeconds,
      if (log.engagementScore != null) 'engagement_score': log.engagementScore,
      if (log.bayesianEligible != null) 'bayesian_eligible': log.bayesianEligible,
      'logged_at': (log.loggedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };

    await _client.from('content_engagement_logs').insert(data);
  }

  @override
  Future<int> consumeResource({
    required String topicId,
    required String resourceType,
  }) async {
    // ARCH-RULE: THE FORBIDDEN WRITE. Flutter is strictly prohibited from writing to student_resource_logs.
    // Invoke a Supabase Edge Function named 'consume-resource'.
    try {
      final response = await _client.functions.invoke(
        'consume-resource',
        body: {
          'topic_id': topicId,
          'resource_type': resourceType,
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      return data['xp_awarded'] as int? ?? 0;
    } catch (e) {
      // Re-throw or handle custom application exceptions here based on architecture.
      rethrow;
    }
  }
}
