import 'package:learnova/features/profile/domain/entities/profile_data.dart';

abstract class ProfileRepository {
  ProfileData getProfileData();

  Future<void> upsertReminderSettings({
    required String time,
    required bool isEmail,
    required bool isPush,
  });

  Future<Map<String, dynamic>?> getReminderSettings();
}

