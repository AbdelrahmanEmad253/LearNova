import 'package:learnova/features/home/domain/entities/level_module.dart';

abstract class LevelModulesRepository {
  LevelModulesData getLevelModules(int levelNumber);
}
