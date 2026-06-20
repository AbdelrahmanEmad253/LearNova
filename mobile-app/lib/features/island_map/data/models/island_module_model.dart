import '../../domain/entities/island_module.dart';

class IslandModuleModel extends IslandModule {
  const IslandModuleModel({
    required super.id,
    required super.levelId,
    required super.title,
    required super.orderIndex,
    required super.xpReward,
    required super.isActive,
  });

  factory IslandModuleModel.fromJson(Map<String, dynamic> json) {
    return IslandModuleModel(
      id: json['id'] as String,
      levelId: json['level_id'] as String,
      title: json['title'] as String,
      orderIndex: json['order_index'] as int,
      xpReward: json['xp_reward'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'title': title,
      'order_index': orderIndex,
      'xp_reward': xpReward,
      'is_active': isActive,
    };
  }
}
