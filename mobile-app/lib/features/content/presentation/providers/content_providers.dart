import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/content/data/repositories/content_navigation_repository_impl.dart';
import 'package:learnova/features/content/domain/usecases/resolve_content_destination_usecase.dart';

final resolveContentDestinationUseCaseProvider =
    Provider<ResolveContentDestinationUseCase>((ref) {
  return const ResolveContentDestinationUseCase(
    ContentNavigationRepositoryImpl(),
  );
});
