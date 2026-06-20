import 'package:learnova/features/home/domain/entities/map_level.dart';
import 'package:learnova/features/home/domain/repositories/map_levels_repository.dart';

class GetMapLevelsUseCase {
  final MapLevelsRepository repository;

  const GetMapLevelsUseCase(this.repository);

  List<MapLevel> call() {
    return repository.getMapLevels();
  }
}
