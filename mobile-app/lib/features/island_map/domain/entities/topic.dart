import 'topic_resource.dart';

class Topic {
  final String id;
  final String moduleId;
  final String title;
  final int orderIndex;
  final int xpReward;
  final bool isActive;
  final List<TopicResource> resources;

  const Topic({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.orderIndex,
    required this.xpReward,
    required this.isActive,
    this.resources = const [],
  });

  Topic copyWith({
    String? id,
    String? moduleId,
    String? title,
    int? orderIndex,
    int? xpReward,
    bool? isActive,
    List<TopicResource>? resources,
  }) {
    return Topic(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      orderIndex: orderIndex ?? this.orderIndex,
      xpReward: xpReward ?? this.xpReward,
      isActive: isActive ?? this.isActive,
      resources: resources ?? this.resources,
    );
  }
}
