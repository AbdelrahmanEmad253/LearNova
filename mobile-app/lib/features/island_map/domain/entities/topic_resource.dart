class TopicResource {
  final String id;
  final String topicId;
  final String formatType;
  final String resourceUrl;
  final int orderIndex;

  const TopicResource({
    required this.id,
    required this.topicId,
    required this.formatType,
    required this.resourceUrl,
    required this.orderIndex,
  });
}
