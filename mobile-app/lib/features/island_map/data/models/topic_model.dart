import '../../domain/entities/topic.dart';
import 'topic_resource_model.dart';

class TopicModel extends Topic {
  const TopicModel({
    required super.id,
    required super.moduleId,
    required super.title,
    required super.orderIndex,
    required super.xpReward,
    required super.isActive,
    super.resources = const [],
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    final resourcesJson = json['topic_resources'] as List<dynamic>?;
    final parsedResources = resourcesJson != null
        ? resourcesJson
            .map((e) => TopicResourceModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <TopicResourceModel>[];

    parsedResources.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return TopicModel(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: json['title'] as String,
      orderIndex: json['order_index'] as int,
      xpReward: json['xp_reward'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      resources: parsedResources,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'order_index': orderIndex,
      'xp_reward': xpReward,
      'is_active': isActive,
      'topic_resources': resources
          .map((e) => (e as TopicResourceModel).toJson())
          .toList(),
    };
  }
}
