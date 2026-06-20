import 'package:shared_preferences/shared_preferences.dart';

class SessionLocalDataSource {
  static const String _kCachedUserId = 'auth.cached_user_id';
  static const String _kCachedUserEmail = 'auth.cached_user_email';
  static const String _kIsLoggedIn = 'auth.is_logged_in';
  static const String _kLastAuthAtMs = 'auth.last_auth_at_ms';

  final SharedPreferences prefs;

  const SessionLocalDataSource(this.prefs);

  Future<void> saveSessionMeta({
    required String userId,
    String? email,
  }) async {
    await prefs.setString(_kCachedUserId, userId);
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_kCachedUserEmail, email);
    }
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setInt(_kLastAuthAtMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearSessionMeta() async {
    await prefs.remove(_kCachedUserId);
    await prefs.remove(_kCachedUserEmail);
    await prefs.setBool(_kIsLoggedIn, false);
  }

  String? cachedUserId() => prefs.getString(_kCachedUserId);

  String? cachedUserEmail() => prefs.getString(_kCachedUserEmail);

  bool isLoggedInFlag() => prefs.getBool(_kIsLoggedIn) ?? false;
}
