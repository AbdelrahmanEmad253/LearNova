import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/topic_progress_entity.dart';
import '../../data/repositories/supabase_curriculum_repository.dart';

// Provides the repository instance
final curriculumRepositoryProvider = Provider<SupabaseCurriculumRepository>((ref) {
  return SupabaseCurriculumRepository(Supabase.instance.client);
});

// A family provider to watch progress for a specific user and topic
// Using a Dart 3 Record for family arguments.
typedef TopicProgressArgs = ({String userId, String topicId, String formatType});

final topicProgressProvider = StreamProvider.family.autoDispose<TopicProgress?, TopicProgressArgs>((ref, args) {
  final repository = ref.watch(curriculumRepositoryProvider);
  return repository.watchTopicProgress(args.userId, args.topicId);
});
