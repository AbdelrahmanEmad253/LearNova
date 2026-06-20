import 'package:learnova/features/auth/domain/entities/avatar_option.dart';
import 'package:learnova/features/auth/domain/repositories/avatar_repository.dart';

class GetAvatarOptionsUseCase {
  final AvatarRepository repository;

  const GetAvatarOptionsUseCase(this.repository);

  List<AvatarOption> call() {
    return repository.getAvatarOptions();
  }
}
