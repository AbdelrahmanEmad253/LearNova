import 'package:learnova/features/content/domain/entities/lesson_topic.dart';

/// Aggregated content type counts for a set of lesson topics.
class LessonTypeBreakdown {
  final int video;
  final int audio;
  final int document;

  const LessonTypeBreakdown({
    required this.video,
    required this.audio,
    required this.document,
  });

  factory LessonTypeBreakdown.fromTopics(List<LessonTopic> topics) {
    int video = 0, audio = 0, document = 0;
    for (final topic in topics) {
      if (topic.hasVideo) video++;
      if (topic.hasAudio) audio++;
      if (topic.hasText) document++;
    }
    return LessonTypeBreakdown(video: video, audio: audio, document: document);
  }

  /// Human-readable summary, e.g. "3 lessons (2 video, 1 audio, 2 document)"
  String toSummary(int totalLessons) {
    final parts = <String>[];
    if (video > 0) parts.add('$video video');
    if (audio > 0) parts.add('$audio audio');
    if (document > 0) parts.add('$document document');
    final noun = totalLessons == 1 ? 'lesson' : 'lessons';
    final detail = parts.isEmpty ? '' : ' (${parts.join(', ')})';
    return '$totalLessons $noun$detail';
  }
}
