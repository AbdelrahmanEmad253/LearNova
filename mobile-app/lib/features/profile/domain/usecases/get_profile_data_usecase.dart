import 'package:learnova/features/profile/domain/entities/profile_data.dart';
import 'package:learnova/features/profile/domain/repositories/profile_repository.dart';

class GetProfileDataUseCase {
  final ProfileRepository repository;

  const GetProfileDataUseCase(this.repository);

  ProfileData call() {
    return repository.getProfileData();
  }
}

