import 'package:learnova/features/home/domain/entities/map_level.dart';

class MapLevelModel {
  final String id;
  final int world;
  final String level;
  final double ratioLeft;
  final double ratioTop;

  MapLevelModel({
    required this.id,
    required this.world,
    required this.level,
    required this.ratioLeft,
    required this.ratioTop,
  });

  MapLevel toEntity() {
    return MapLevel(
      id: id,
      world: world,
      level: level,
      ratioLeft: ratioLeft,
      ratioTop: ratioTop,
    );
  }
}
