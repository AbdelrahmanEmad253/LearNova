import 'package:learnova/features/home/data/datasources/level_modules_local_data_source.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:learnova/features/home/domain/repositories/level_modules_repository.dart';

class LevelModulesRepositoryImpl extends LevelModulesRepository {
  final LevelModulesLocalDataSource _dataSource;

  LevelModulesRepositoryImpl(this._dataSource);

  @override
  LevelModulesData getLevelModules(int levelNumber) {
    return _dataSource.getLevelModules(levelNumber);
  }
}
