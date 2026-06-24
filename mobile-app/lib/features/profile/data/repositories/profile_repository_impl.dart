import 'package:learnova/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:learnova/features/profile/domain/entities/profile_data.dart';
import 'package:learnova/features/profile/domain/repositories/profile_repository.dart';

import 'package:learnova/features/profile/data/datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource localDataSource;
  final ProfileRemoteDataSource remoteDataSource;

  const ProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  ProfileData getProfileData() {
    return localDataSource.getProfileData().toEntity();
  }

  @override
  Future<void> upsertReminderSettings({
    required String time,
    required bool isEmail,
    required bool isPush,
  }) async {
    await remoteDataSource.upsertReminderSettings(
      time: time,
      isEmail: isEmail,
      isPush: isPush,
    );
  }

  @override
  Future<Map<String, dynamic>?> getReminderSettings() async {
    return await remoteDataSource.getReminderSettings();
  }
}

