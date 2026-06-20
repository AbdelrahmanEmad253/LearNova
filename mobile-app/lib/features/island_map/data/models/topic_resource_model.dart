import '../../domain/entities/topic_resource.dart';

class TopicResourceModel extends TopicResource {
  const TopicResourceModel({
    required super.id,
    required super.topicId,
    required super.formatType,
    required super.resourceUrl,
    required super.orderIndex,
  });

  factory TopicResourceModel.fromJson(Map<String, dynamic> json) {
    return TopicResourceModel(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      formatType: json['format_type'] as String,
      resourceUrl: json['resource_url'] as String,
      orderIndex: json['order_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'format_type': formatType,
      'resource_url': resourceUrl,
      'order_index': orderIndex,
    };
  }
}
