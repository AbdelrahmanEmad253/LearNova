/// A single lesson topic from the Supabase `lesson_topic` table.
///
/// Each topic can have up to 3 content URLs for different VARK learning styles:
/// - [videoUrlVisual] for visual learners
/// - [audioUrlAuditory] for auditory learners
/// - [textUrlRead] for read/write learners
class LessonTopic {
  final String id;
  final String moduleId;
  final String title;
  final String? videoUrlVisual;
  final String? audioUrlAuditory;
  final String? textUrlRead;

  const LessonTopic({
    required this.id,
    required this.moduleId,
    required this.title,
    this.videoUrlVisual,
    this.audioUrlAuditory,
    this.textUrlRead,
  });

  /// Returns the list of available content types for this topic.
  List<String> get availableTypes => [
        if (hasVideo) 'video',
        if (hasAudio) 'audio',
        if (hasText) 'text',
      ];

  bool get hasVideo => videoUrlVisual != null && videoUrlVisual!.trim().isNotEmpty;
  bool get hasAudio => audioUrlAuditory != null && audioUrlAuditory!.trim().isNotEmpty;
  bool get hasText => textUrlRead != null && textUrlRead!.trim().isNotEmpty;
  bool get hasAnyContent => hasVideo || hasAudio || hasText;
}
