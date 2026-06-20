import 'package:learnova/features/content/domain/entities/content_destination.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';
import 'package:learnova/features/content/domain/repositories/content_navigation_repository.dart';

class ContentNavigationRepositoryImpl implements ContentNavigationRepository {
  const ContentNavigationRepositoryImpl();

  @override
  ContentDestination resolveDestination(ContentItemPayload item) {
    final String normalizedType = item.contentType.trim().toLowerCase();

    if (normalizedType == 'audio') {
      return ContentDestination.audio;
    }

    if (normalizedType == 'video') {
      return ContentDestination.video;
    }

    return ContentDestination.document;
  }
}
