import '../entities/island_module.dart';
import '../entities/topic.dart';

abstract class IslandMapRepository {
  Future<String?> getLevelIdByOrderIndex(int orderIndex);
  Future<List<IslandModule>> getModulesForLevel(String levelId);
  Future<List<Topic>> getTopicsForModule(
    String moduleId, {
    required String learningStyle,
  });
}
