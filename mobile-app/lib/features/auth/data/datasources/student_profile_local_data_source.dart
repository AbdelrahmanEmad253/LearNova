import 'dart:convert';
import 'package:learnova/features/auth/data/models/student_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileLocalDataSource {
  static const String _kCachedProfile = 'auth.cached_student_profile';

  final SharedPreferences prefs;

  const StudentProfileLocalDataSource(this.prefs);

  Future<void> cacheProfile(StudentProfileModel profile) async {
    await prefs.setString(_kCachedProfile, jsonEncode(profile.toJson()));
  }

  StudentProfileModel? getCachedProfile() {
    final jsonString = prefs.getString(_kCachedProfile);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return StudentProfileModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await prefs.remove(_kCachedProfile);
  }
}
