import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityTrackingService {
  final SupabaseClient _client;
  const ActivityTrackingService(this._client);

  // Log a learning activity
  Future<bool> logActivity({
    required String moduleId,
    required String levelId,
    required int durationSeconds,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || durationSeconds < 5) return false;
    try {
      await _client.from('user_activity_log').insert({
        'user_id': user.id,
        'module_id': moduleId,
        'level_id': levelId,
        'duration_seconds': durationSeconds,
        'activity_date': DateTime.now().toIso8601String().substring(0, 10),
      });
      return true;
    } catch (e) {
      debugPrint('[ActivityTracking] logActivity error: $e');
      return false;
    }
  }

  // Get total time in hours (all time)
  Future<double> getTotalTime() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final result = await _client
          .from('user_activity_log')
          .select('duration_seconds')
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 5));
      final rows = List<Map<String, dynamic>>.from(result);
      final totalSeconds = rows.fold<int>(
          0, (sum, row) => sum + ((row['duration_seconds'] as int?) ?? 0));
      return totalSeconds / 3600.0;
    } catch (e) {
      debugPrint('[ActivityTracking] getTotalTime error: $e');
      return 0;
    }
  }

  // Get time spent in current week (hours)
  Future<double> getWeeklyTime() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      final weekStartStr =
          DateTime(weekStart.year, weekStart.month, weekStart.day)
              .toIso8601String()
              .substring(0, 10);
      final result = await _client
          .from('user_activity_log')
          .select('duration_seconds')
          .eq('user_id', user.id)
          .gte('activity_date', weekStartStr)
          .timeout(const Duration(seconds: 5));
      final rows = List<Map<String, dynamic>>.from(result);
      final totalSeconds = rows.fold<int>(
          0, (sum, row) => sum + ((row['duration_seconds'] as int?) ?? 0));
      return totalSeconds / 3600.0;
    } catch (e) {
      debugPrint('[ActivityTracking] getWeeklyTime error: $e');
      return 0;
    }
  }

  // Get time spent in current month (hours)
  Future<double> getMonthlyTime() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final now = DateTime.now();
      final monthStartStr =
          DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
      final result = await _client
          .from('user_activity_log')
          .select('duration_seconds')
          .eq('user_id', user.id)
          .gte('activity_date', monthStartStr)
          .timeout(const Duration(seconds: 5));
      final rows = List<Map<String, dynamic>>.from(result);
      final totalSeconds = rows.fold<int>(
          0, (sum, row) => sum + ((row['duration_seconds'] as int?) ?? 0));
      return totalSeconds / 3600.0;
    } catch (e) {
      debugPrint('[ActivityTracking] getMonthlyTime error: $e');
      return 0;
    }
  }

  // Get average time per level (hours)
  Future<double> getAverageTimePerLevel() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final result = await _client
          .from('user_activity_log')
          .select('duration_seconds, level_id')
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 10));
          
      final rows = List<Map<String, dynamic>>.from(result);
      if (rows.isEmpty) return 0;

      final Map<String, int> levelTotals = {};
      for (final row in rows) {
        final levelId = row['level_id']?.toString() ?? 'unknown';
        final seconds = (row['duration_seconds'] as int?) ?? 0;
        levelTotals[levelId] = (levelTotals[levelId] ?? 0) + seconds;
      }
      if (levelTotals.isEmpty) return 0;
      
      final avgSeconds =
          levelTotals.values.fold<int>(0, (a, b) => a + b) / levelTotals.length;
      return avgSeconds / 3600.0;
    } catch (e) {
      debugPrint('[ActivityTracking] getAverageTimePerLevel error: $e');
      return 0;
    }
  }

  // Get weekly activity as List<bool> for Sun-Sat of current week
  Future<List<bool>> getWeeklyActivity() async {
    final user = _client.auth.currentUser;
    if (user == null) return List.filled(7, false);
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      final weekStartDate =
          DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekStartStr = weekStartDate.toIso8601String().substring(0, 10);
      
      final result = await _client
          .from('user_activity_log')
          .select('activity_date')
          .eq('user_id', user.id)
          .gte('activity_date', weekStartStr)
          .timeout(const Duration(seconds: 5));
          
      final rows = List<Map<String, dynamic>>.from(result);
      final activeDates = rows.map((r) {
        final dt = r['activity_date']?.toString() ?? '';
        return dt.length >= 10 ? dt.substring(0, 10) : '';
      }).toSet();
      
      return List.generate(7, (i) {
        final day = weekStartDate.add(Duration(days: i));
        final dayStr = day.toIso8601String().substring(0, 10);
        return activeDates.contains(dayStr);
      });
    } catch (e) {
      debugPrint('[ActivityTracking] getWeeklyActivity error: $e');
      return List.filled(7, false);
    }
  }

  // Get active streak from user_streaks table
  Future<int> getActiveWeekStreak() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final result = await _client
          .from('user_streaks')
          .select('current_streak_days')
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (result == null) return 0;
      return (result['current_streak_days'] as int?) ?? 0;
    } catch (e) {
      debugPrint('[ActivityTracking] getActiveWeekStreak error: $e');
      return 0;
    }
  }
}

