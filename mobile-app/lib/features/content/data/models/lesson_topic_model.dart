import 'package:learnova/features/content/domain/entities/lesson_topic.dart';

class LessonTopicModel extends LessonTopic {
  const LessonTopicModel({
    required super.id,
    required super.moduleId,
    required super.title,
    super.videoUrlVisual,
    super.audioUrlAuditory,
    super.textUrlRead,
  });

  factory LessonTopicModel.fromJson(Map<String, dynamic> json) {
    return LessonTopicModel(
      id: json['id']?.toString() ?? '',
      moduleId: json['module_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      videoUrlVisual: _nonEmpty(json['video_url_visual']),
      audioUrlAuditory: _nonEmpty(json['audio_url_auditory']),
      textUrlRead: _nonEmpty(json['text_url_read']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'module_id': moduleId,
        'title': title,
        'video_url_visual': videoUrlVisual,
        'audio_url_auditory': audioUrlAuditory,
        'text_url_read': textUrlRead,
      };

  /// Returns null for null, empty, or whitespace-only strings.
  /// Also filters out local file paths (e.g., E:\...) which are invalid URLs.
  static String? _nonEmpty(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    // Filter out local file paths (Windows drive letters).
    if (RegExp(r'^[A-Za-z]:\\').hasMatch(str)) return null;
    return str;
  }
}
