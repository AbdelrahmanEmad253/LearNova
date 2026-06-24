import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // This is now handled by the Curriculum repository (TopicSessionNotifier)
    // but we can leave it here or return true if something else still calls it.
    return true;
  }

  // Get total time in hours (all time)
  Future<double> getTotalTime() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final result = await _client
          .from('content_engagement_logs')
          .select('time_spent_seconds')
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 5));
      final rows = List<Map<String, dynamic>>.from(result);
      final totalSeconds = rows.fold<int>(
          0, (sum, row) => sum + ((row['time_spent_seconds'] as int?) ?? 0));
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
          .from('content_engagement_logs')
          .select('time_spent_seconds')
          .eq('user_id', user.id)
          .gte('logged_at', weekStartStr)
          .timeout(const Duration(seconds: 5));
      final rows = List<Map<String, dynamic>>.from(result);
      final totalSeconds = rows.fold<int>(
          0, (sum, row) => sum + ((row['time_spent_seconds'] as int?) ?? 0));
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
          .from('content_engagement_logs')
          .select('time_spent_seconds')
          .eq('user_id', user.id)
          .gte('logged_at', monthStartStr)
          .timeout(const Duration(seconds: 5));
      final rows = List<Map<String, dynamic>>.from(result);
      final totalSeconds = rows.fold<int>(
          0, (sum, row) => sum + ((row['time_spent_seconds'] as int?) ?? 0));
      return totalSeconds / 3600.0;
    } catch (e) {
      debugPrint('[ActivityTracking] getMonthlyTime error: $e');
      return 0;
    }
  }

  // Get average time per level (hours). Note: using topic_id as proxy for now since logs are per topic.
  Future<double> getAverageTimePerLevel() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final result = await _client
          .from('content_engagement_logs')
          .select('time_spent_seconds, topic_id')
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 10));

      final rows = List<Map<String, dynamic>>.from(result);
      if (rows.isEmpty) return 0;

      final Map<String, int> topicTotals = {};
      for (final row in rows) {
        final topicId = row['topic_id']?.toString() ?? 'unknown';
        final seconds = (row['time_spent_seconds'] as int?) ?? 0;
        topicTotals[topicId] = (topicTotals[topicId] ?? 0) + seconds;
      }
      if (topicTotals.isEmpty) return 0;

      final avgSeconds =
          topicTotals.values.fold<int>(0, (a, b) => a + b) / topicTotals.length;
      return avgSeconds / 3600.0;
    } catch (e) {
      debugPrint('[ActivityTracking] getAverageTimePerTopic error: $e');
      return 0;
    }
  }

  // Get weekly activity as List<bool> for Sun-Sat of current week using SharedPreferences
  Future<List<bool>> getWeeklyActivity() async {
    final user = _client.auth.currentUser;
    if (user == null) return List.filled(7, false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'weekly_app_opens_${user.id}';

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      final weekStartDate = DateTime(
          weekStart.year, weekStart.month, weekStart.day);

      // We store a comma separated list of ISO date strings for the current week in SharedPreferences
      final activeDatesStr = prefs.getString(key) ?? '';
      final activeDates = activeDatesStr
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet();

      // Filter out dates not in this week just in case
      final currentWeekActiveDates = <String>{};
      for (final dateStr in activeDates) {
        if (dateStr.length >= 10) {
          final date = DateTime.parse('${dateStr.substring(0, 10)}T00:00:00Z');
          if (date.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
              date.isBefore(weekStartDate.add(const Duration(days: 7)))) {
            currentWeekActiveDates.add(dateStr.substring(0, 10));
          }
        }
      }

      // Clean up old entries if needed
      if (currentWeekActiveDates.length != activeDates.length) {
        await prefs.setString(key, currentWeekActiveDates.join(','));
      }

      return List.generate(7, (i) {
        final day = weekStartDate.add(Duration(days: i));
        final dayStr = day.toIso8601String().substring(0, 10);
        return currentWeekActiveDates.contains(dayStr);
      });
    } catch (e) {
      debugPrint('[ActivityTracking] getWeeklyActivity error: $e');
      return List.filled(7, false);
    }
  }

  Future<void> markAppOpenToday() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = 'weekly_app_opens_${user.id}';

      final now = DateTime.now();
      final todayStr = now.toIso8601String().substring(0, 10);

      final activeDatesStr = prefs.getString(key) ?? '';
      final activeDates = activeDatesStr
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet();

      if (!activeDates.contains(todayStr)) {
        activeDates.add(todayStr);
        await prefs.setString(key, activeDates.join(','));
      }
    } catch (e) {
      debugPrint('[ActivityTracking] markAppOpenToday error: $e');
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

  Future<double> getJourneyCompletion({
      required String track,
      required String learningStyle,
    }) async {
      final user = _client.auth.currentUser;
      if (user == null || track.isEmpty || learningStyle.isEmpty) return 0.0;
      try {
        // Fetch course ids for track
        final courses = await _client.from('courses').select('id').eq(
            'track', track);
        if ((courses as List).isEmpty) return 0.0;
        final courseIds = courses.map((c) => c['id']).toList();

        // Fetch level ids
        final levels = await _client.from('levels').select('id').inFilter(
            'course_id', courseIds);
        if ((levels as List).isEmpty) return 0.0;
        final levelIds = levels.map((l) => l['id']).toList();

        // Fetch module ids
        final modules = await _client.from('modules').select('id').inFilter(
            'level_id', levelIds);
        if ((modules as List).isEmpty) return 0.0;
        final moduleIds = modules.map((m) => m['id']).toList();

        // Fetch topic ids
        final topics = await _client.from('topics').select('id').inFilter(
            'module_id', moduleIds);
        if ((topics as List).isEmpty) return 0.0;
        final topicIds = topics.map((t) => t['id']).toList();

        // Count resources matching learning style
        final resources = await _client.from('topic_resources').select(
            'topic_id').eq('format_type', learningStyle).inFilter(
            'topic_id', topicIds);
        final validTopicIds = (resources as List)
            .map((r) => r['topic_id'])
            .toSet();
        final totalTopicsCount = validTopicIds.length;
        if (totalTopicsCount == 0) return 0.0;

        // Count completed
        final completed = await _client
            .from('student_progress')
            .select(
            'topic_id')
            .eq('user_id', user.id)
            .eq('status', 'completed')
            .inFilter('topic_id', validTopicIds.toList());
        final completedCount = (completed as List).length;

        return (completedCount / totalTopicsCount).clamp(0.0, 1.0);
      } catch (e) {
        debugPrint('[ActivityTracking] getJourneyCompletion error: $e');
        return 0.0;
      }
    }
  }

