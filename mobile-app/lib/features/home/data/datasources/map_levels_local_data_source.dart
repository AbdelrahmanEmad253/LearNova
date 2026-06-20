import 'package:learnova/features/home/data/models/map_level_model.dart';

class MapLevelsLocalDataSource {
  const MapLevelsLocalDataSource();

  static const double _baseWidth = 392;
  static const double _baseHeight = 2604;

  List<MapLevelModel> getMapLevels() {
    return [
      MapLevelModel(
          id: 'w1_l1',
          world: 1,
          level: '1',
          ratioLeft: 200 / _baseWidth,
          ratioTop: 170 / _baseHeight),
      MapLevelModel(
          id: 'w1_l2',
          world: 1,
          level: '2',
          ratioLeft: 135 / _baseWidth,
          ratioTop: 400 / _baseHeight),
      MapLevelModel(
          id: 'w1_l3',
          world: 1,
          level: '3',
          ratioLeft: 115 / _baseWidth,
          ratioTop: 675 / _baseHeight),
      MapLevelModel(
          id: 'w1_e',
          world: 1,
          level: 'E',
          ratioLeft: 235 / _baseWidth,
          ratioTop: 810 / _baseHeight),
      MapLevelModel(
          id: 'w2_l1',
          world: 2,
          level: '1',
          ratioLeft: 300 / _baseWidth,
          ratioTop: 1140 / _baseHeight),
      MapLevelModel(
          id: 'w2_l2',
          world: 2,
          level: '2',
          ratioLeft: 60 / _baseWidth,
          ratioTop: 1210 / _baseHeight),
      MapLevelModel(
          id: 'w2_l3',
          world: 2,
          level: '3',
          ratioLeft: 165 / _baseWidth,
          ratioTop: 1425 / _baseHeight),
      MapLevelModel(
          id: 'w2_e',
          world: 2,
          level: 'E',
          ratioLeft: 258 / _baseWidth,
          ratioTop: 1575 / _baseHeight),
      MapLevelModel(
          id: 'w3_l1',
          world: 3,
          level: '1',
          ratioLeft: 90 / _baseWidth,
          ratioTop: 1860 / _baseHeight),
      MapLevelModel(
          id: 'w3_l2',
          world: 3,
          level: '2',
          ratioLeft: 255 / _baseWidth,
          ratioTop: 1955 / _baseHeight),
      MapLevelModel(
          id: 'w3_l3',
          world: 3,
          level: '3',
          ratioLeft: 130 / _baseWidth,
          ratioTop: 2085 / _baseHeight),
      MapLevelModel(
          id: 'w3_e',
          world: 3,
          level: 'E',
          ratioLeft: 165 / _baseWidth,
          ratioTop: 2290 / _baseHeight),
    ];
  }
}
