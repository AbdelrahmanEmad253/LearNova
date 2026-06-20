import 'package:flutter/foundation.dart';
import 'package:learnova/features/content/data/models/lesson_topic_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches module data and lesson topics from Supabase.
///
/// Real Supabase schema:
/// - `module`: id, level_id, title, description
/// - `lesson_topic`: id, module_id, title, video_url_visual, audio_url_auditory, text_url_read
///
/// Each `lesson_topic` row can have up to 3 content URLs (VARK learning styles).
/// Each non-null URL generates a separate [ModuleContentItem] so the UI
/// automatically adapts its lesson count and types.
class ModuleContentRemoteDataSource {
  final SupabaseClient _client;

  const ModuleContentRemoteDataSource(this._client);

  /// Fetch lesson topics for a specific module from Supabase.
  ///
  /// Returns a list of [LessonTopicModel]s which contain all VARK URLs.
  /// The client is responsible for filtering them based on the user's style.
  Future<List<LessonTopicModel>> getLessonTopicsForModule(
    String moduleId,
  ) async {
    try {
      debugPrint('[LessonTopics] Fetching for moduleId: "$moduleId"');
      final raw = await _client
          .from('lesson_topic')
          .select('id, module_id, title, video_url_visual, audio_url_auditory, text_url_read')
          .eq('module_id', moduleId)
          .timeout(const Duration(seconds: 10));

      final rows = List<Map<String, dynamic>>.from(raw);
      debugPrint('[LessonTopics] Got ${rows.length} rows for "$moduleId"');
      for (final row in rows) {
        debugPrint('[LessonTopics]   → ${row['id']}: ${row['title']}');
      }
      if (rows.isEmpty) return [];

      return rows.map((row) => LessonTopicModel.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[LessonTopics] ERROR for "$moduleId": $e');
      return [];
    }
  }

  /// Fetch the module metadata (title, description) from Supabase.
  Future<Map<String, String>?> getModuleInfo(String moduleId) async {
    try {
      final raw = await _client
          .from('module')
          .select('id, title, description')
          .eq('id', moduleId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (raw == null) return null;

      return {
        'id': raw['id']?.toString() ?? moduleId,
        'title': raw['title']?.toString() ?? '',
        'description': raw['description']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// Fetch all modules for a given level from Supabase.
  Future<List<Map<String, String>>> getModulesForLevel(
    String levelId,
  ) async {
    try {
      final raw = await _client
          .from('module')
          .select('id, title, description')
          .eq('level_id', levelId)
          .timeout(const Duration(seconds: 5));

      final rows = List<Map<String, dynamic>>.from(raw);
      return rows.map((row) {
        return {
          'id': row['id']?.toString() ?? '',
          'title': row['title']?.toString() ?? '',
          'description': row['description']?.toString() ?? '',
        };
      }).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  /// Fetch all levels for a given track from Supabase.
  Future<List<Map<String, dynamic>>> getLevelsForTrack(
    String trackId,
  ) async {
    try {
      final raw = await _client
          .from('level')
          .select('id, title, sequence_order')
          .eq('track_id', trackId)
          .order('sequence_order')
          .timeout(const Duration(seconds: 5));

      return List<Map<String, dynamic>>.from(raw);
    } catch (_) {
      return [];
    }
  }
}
