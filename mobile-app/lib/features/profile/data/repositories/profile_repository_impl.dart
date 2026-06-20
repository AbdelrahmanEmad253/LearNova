import 'package:learnova/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:learnova/features/profile/domain/entities/profile_data.dart';
import 'package:learnova/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource localDataSource;

  const ProfileRepositoryImpl(this.localDataSource);

  @override
  ProfileData getProfileData() {
    return localDataSource.getProfileData().toEntity();
  }
}

