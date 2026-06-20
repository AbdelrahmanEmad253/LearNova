import 'package:learnova/features/island_map/domain/entities/island_module.dart';
import 'package:learnova/features/island_map/domain/entities/topic.dart';
import 'package:learnova/features/island_map/domain/repositories/island_map_repository.dart';
import 'package:learnova/features/island_map/data/datasources/island_map_remote_data_source.dart';

class IslandMapRepositoryImpl implements IslandMapRepository {
  final IslandMapRemoteDataSource remoteDataSource;

  const IslandMapRepositoryImpl(this.remoteDataSource);

  @override
  Future<String?> getLevelIdByOrderIndex(int orderIndex) {
    return remoteDataSource.getLevelIdByOrderIndex(orderIndex);
  }

  @override
  Future<List<IslandModule>> getModulesForLevel(String levelId) {
    return remoteDataSource.getModulesForLevel(levelId);
  }

  @override
  Future<List<Topic>> getTopicsForModule(
    String moduleId, {
    required String learningStyle,
  }) async {
    final allTopics = await remoteDataSource.getTopicsWithResources(moduleId);
    final targetFormat = _toFormatType(learningStyle);

    return allTopics.map((topic) {
      if (topic.resources.isEmpty) return topic;

      // Filter resources: try to find the preferred one.
      final preferred = topic.resources.where((r) {
        final rType = r.formatType.trim().toLowerCase();
        final tType = targetFormat.trim().toLowerCase();
        return rType == tType;
      }).toList();

      if (preferred.isNotEmpty) {
        return topic.copyWith(resources: preferred);
      }

      // Fallback: if no preferred, take the first one available
      return topic.copyWith(resources: [topic.resources.first]);
    }).toList();
  }

  static String _toFormatType(String learningStyle) {
    return switch (learningStyle.toLowerCase()) {
      'visual' => 'Visual',
      'auditory' => 'Auditory',
      'textual' || 'readwrite' => 'Textual',
      _ => 'Visual',
    };
  }
}
