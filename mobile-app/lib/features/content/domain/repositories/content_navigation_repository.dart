import 'package:learnova/features/content/domain/entities/content_destination.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';

abstract class ContentNavigationRepository {
  ContentDestination resolveDestination(ContentItemPayload item);
}
