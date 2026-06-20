import 'package:learnova/features/content/domain/entities/lesson_topic.dart';

/// Resolves the preferred content URL and type for a [LessonTopic]
/// based on the user's VARK learning style.
///
/// Implements a fallback priority chain so the user always gets content
/// even if their preferred modality is missing.
class ContentUrlResolver {
  const ContentUrlResolver._();

  /// VARK priority chains.
  /// Each entry defines: preferred → fallback1 → fallback2.
  static const Map<String, List<String>> _priorityChains = {
    'visual': ['video', 'audio', 'text'],
    'auditory': ['audio', 'video', 'text'],
    'readwrite': ['text', 'video', 'audio'],
    'kinesthetic': ['video', 'audio', 'text'],
  };

  /// Resolves the best content URL for a topic given the user's VARK style.
  ///
  /// Returns a [ResolvedContent] with the URL, content type, and whether
  /// a fallback was used.
  static ResolvedContent resolve(LessonTopic topic, String? varkStyle) {
    final chain = _priorityChains[varkStyle?.toLowerCase()] ??
        _priorityChains['visual']!;

    for (final type in chain) {
      final url = _urlForType(topic, type);
      if (url != null) {
        final isFallback = type != chain.first;
        return ResolvedContent(
          url: url,
          contentType: type,
          fallbackUsed: isFallback,
        );
      }
    }

    // All URLs are null — no content available.
    return const ResolvedContent(
      url: null,
      contentType: 'text',
      fallbackUsed: true,
    );
  }

  /// Returns all available content URLs for the topic as a map.
  static Map<String, String?> allUrls(LessonTopic topic) => {
        'video': topic.hasVideo ? topic.videoUrlVisual : null,
        'audio': topic.hasAudio ? topic.audioUrlAuditory : null,
        'text': topic.hasText ? topic.textUrlRead : null,
      };

  static String? _urlForType(LessonTopic topic, String type) {
    switch (type) {
      case 'video':
        return topic.hasVideo ? topic.videoUrlVisual : null;
      case 'audio':
        return topic.hasAudio ? topic.audioUrlAuditory : null;
      case 'text':
        return topic.hasText ? topic.textUrlRead : null;
      default:
        return null;
    }
  }
}

/// The result of resolving a content URL for a topic + VARK style.
class ResolvedContent {
  /// The resolved URL (null if no content is available).
  final String? url;

  /// The content type: 'video', 'audio', or 'text'.
  final String contentType;

  /// True if the preferred VARK type was unavailable and a fallback was used.
  final bool fallbackUsed;

  const ResolvedContent({
    required this.url,
    required this.contentType,
    required this.fallbackUsed,
  });
}
