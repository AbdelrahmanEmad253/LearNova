import 'package:learnova/features/content/domain/entities/content_destination.dart';
import 'package:learnova/features/content/domain/entities/content_item_payload.dart';
import 'package:learnova/features/content/domain/repositories/content_navigation_repository.dart';

class ResolveContentDestinationUseCase {
  final ContentNavigationRepository _repository;

  const ResolveContentDestinationUseCase(this._repository);

  ContentDestination call(ContentItemPayload item) {
    return _repository.resolveDestination(item);
  }
}
