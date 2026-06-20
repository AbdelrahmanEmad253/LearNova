import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learnova/features/island_map/data/models/island_module_model.dart';
import 'package:learnova/features/island_map/data/models/topic_model.dart';

class IslandMapRemoteDataSource {
  final SupabaseClient _client;

  const IslandMapRemoteDataSource(this._client);

  /// Fetch level ID by order_index
  Future<String?> getLevelIdByOrderIndex(int orderIndex) async {
    try {
      final raw = await _client
          .from('levels')
          .select('id')
          .eq('order_index', orderIndex)
          .limit(1)
          .maybeSingle();
      
      return raw?['id'] as String?;
    } catch (e) {
      // Re-throw to see what the exact error is
      throw Exception('Failed to fetch level id: $e');
    }
  }

  /// Fetch active modules for a level, ordered by order_index.
  Future<List<IslandModuleModel>> getModulesForLevel(String levelId) async {
    try {
      final raw = await _client
          .from('modules')
          .select()
          .eq('level_id', levelId)
          .eq('is_active', true)
          .order('order_index')
          .timeout(const Duration(seconds: 10));

      return List<Map<String, dynamic>>.from(raw)
          .map((e) => IslandModuleModel.fromJson(e))
          .toList();
    } catch (e) {
      // Return empty or let it throw based on preferred error handling.
      // Re-throwing allows FutureProvider to show an error state.
      rethrow;
    }
  }

  /// Fetch topics for a module with all associated resources.
  Future<List<TopicModel>> getTopicsWithResources(
    String moduleId,
  ) async {
    try {
      final raw = await _client
          .from('topics')
          .select('*, topic_resources(*)')
          .eq('module_id', moduleId)
          .eq('is_active', true)
          .order('order_index')
          .timeout(const Duration(seconds: 10));

      return List<Map<String, dynamic>>.from(raw)
          .map((e) => TopicModel.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
