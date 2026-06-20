import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:learnova/features/home/domain/repositories/level_modules_repository.dart';

class GetLevelModulesUseCase {
  final LevelModulesRepository _repository;

  const GetLevelModulesUseCase(this._repository);

  LevelModulesData call(int levelNumber) {
    return _repository.getLevelModules(levelNumber);
  }
}
