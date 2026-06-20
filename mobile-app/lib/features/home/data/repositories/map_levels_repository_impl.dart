import 'package:learnova/features/home/data/datasources/map_levels_local_data_source.dart';
import 'package:learnova/features/home/domain/entities/map_level.dart';
import 'package:learnova/features/home/domain/repositories/map_levels_repository.dart';

class MapLevelsRepositoryImpl implements MapLevelsRepository {
  final MapLevelsLocalDataSource localDataSource;

  const MapLevelsRepositoryImpl(this.localDataSource);

  @override
  List<MapLevel> getMapLevels() {
    return localDataSource
        .getMapLevels()
        .map((item) => item.toEntity())
        .toList();
  }
}
