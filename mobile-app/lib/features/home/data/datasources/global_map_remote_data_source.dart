import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalMapRemoteDataSource {
  final SupabaseClient _supabaseClient;

  GlobalMapRemoteDataSource(this._supabaseClient);

  static const Duration _queryTimeout = Duration(seconds: 10);

  Future<List<LevelModulesData>> getGlobalMapData(String track) async {
    // 1. Fetch BOTH the Shared Foundation course and the track-specific course
    final coursesResponse = await _supabaseClient
        .from('courses')
        .select('id, order_index, is_foundation')
        .or('is_foundation.eq.true,track.eq.$track')
        .eq('is_active', true)
        .order('order_index', ascending: true)
        .timeout(_queryTimeout);

    final List<Map<String, dynamic>> courses =
        List<Map<String, dynamic>>.from(coursesResponse);
    if (courses.isEmpty) return [];

    final String? foundationCourseId = courses
        .firstWhere((c) => c['is_foundation'] == true,
            orElse: () => <String, dynamic>{})['id']
        ?.toString();

    final List<String> courseIds =
        courses.map((c) => c['id'] as String).toList();

    // 2. Fetch levels for ALL relevant courses, including modules, topics, and topic_resources
    // We order by course_id first (implicitly by the order we fetched courses) then level order_index.
    // However, Supabase doesn't support ordering by a related table's column in a simple way without joining.
    // We will fetch and then sort manually in Dart to ensure Foundation levels come first.
    final response = await _supabaseClient
        .from('levels')
        .select('*, modules(*, topics(*, topic_resources(id)))')
        .inFilter('course_id', courseIds)
        .eq('is_active', true)
        .timeout(_queryTimeout);

    final List<Map<String, dynamic>> levelRows =
        List<Map<String, dynamic>>.from(response);

    // Sort levels: first by course's order_index, then by level's order_index
    final Map<String, int> courseOrderMap = {
      for (var c in courses) c['id']: c['order_index'] as int
    };

    levelRows.sort((a, b) {
      final aCourseId = a['course_id'] as String;
      final bCourseId = b['course_id'] as String;
      final aCourseOrder = courseOrderMap[aCourseId] ?? 999;
      final bCourseOrder = courseOrderMap[bCourseId] ?? 999;

      if (aCourseOrder != bCourseOrder) {
        return aCourseOrder.compareTo(bCourseOrder);
      }
      return (a['order_index'] as int).compareTo(b['order_index'] as int);
    });

    // Fetch user resource logs and progress for all topics
    final user = _supabaseClient.auth.currentUser;
    final Map<String, int> topicCompletedCounts = {};
    final Map<String, String> topicProgressStatus = {};
    
    if (user != null) {
      try {
        // Fetch student_progress to know if a topic is fully 'completed'
        final progressRes = await _supabaseClient
            .from('student_progress')
            .select('topic_id, status')
            .eq('user_id', user.id)
            .timeout(_queryTimeout);
            
        for (final row in List<Map<String, dynamic>>.from(progressRes)) {
          final tid = row['topic_id']?.toString() ?? '';
          topicProgressStatus[tid] = row['status']?.toString() ?? '';
        }

        // Fetch resource logs for partial 'in_progress' percentages
        final logsRes = await _supabaseClient
            .from('student_resource_logs')
            .select('topic_id')
            .eq('user_id', user.id)
            .eq('completed', true)
            .timeout(_queryTimeout);
            
        for (final row in List<Map<String, dynamic>>.from(logsRes)) {
          final tid = row['topic_id']?.toString() ?? '';
          topicCompletedCounts[tid] = (topicCompletedCounts[tid] ?? 0) + 1;
        }
      } catch (e) {
        // Fallback to empty
      }
    }

    final List<LevelModulesData> levelDataList = [];
    final List<LevelModule> foundationModules = [];
    int appLevelIndex = 1;

    for (final levelRow in levelRows) {
      final String courseId = levelRow['course_id'] as String;
      final bool isFoundation = courseId == foundationCourseId;
      final levelId = levelRow['id'] as String;
      final levelTitle = levelRow['title'] as String;

      final modulesData = levelRow['modules'] as List<dynamic>? ?? [];
      final List<Map<String, dynamic>> sortedModules =
          List<Map<String, dynamic>>.from(modulesData)
              .where((m) => m['is_active'] != false)
              .toList();
      sortedModules.sort((a, b) =>
          (a['order_index'] as int).compareTo(b['order_index'] as int));

      final List<LevelModule> currentLevelModules = [];

      for (final modRow in sortedModules) {
        final modId = modRow['id'] as String;
        final modNumber = modRow['order_index'] as int;
        final modTitle = modRow['title'] as String;

        final topicsData = modRow['topics'] as List<dynamic>? ?? [];
        final List<Map<String, dynamic>> sortedTopics =
            List<Map<String, dynamic>>.from(topicsData)
                .where((t) => t['is_active'] != false)
                .toList();
        sortedTopics.sort((a, b) =>
            (a['order_index'] as int).compareTo(b['order_index'] as int));

        final List<ModuleSection> sections = sortedTopics.map((topicRow) {
          final tId = topicRow['id'] as String;
          final completed = topicCompletedCounts[tId] ?? 0;
          final status = topicProgressStatus[tId] ?? '';

          final resourcesData =
              topicRow['topic_resources'] as List<dynamic>? ?? [];
          final totalResources = resourcesData.length;

          double progress = 0.0;
          if (status == 'completed') {
            progress = 1.0;
          } else if (totalResources > 0) {
            progress = completed / totalResources;
            if (progress > 1.0) progress = 1.0;
          } else if (completed > 0) {
            progress = 1.0;
          }

          return ModuleSection(
            id: tId,
            title: topicRow['title'] as String,
            description: topicRow['description'] as String? ?? '',
            progressPercentage: progress,
            isCompleted: progress >= 1.0,
          );
        }).toList();

        final double totalProgress = sections.isEmpty
            ? 0.0
            : sections.fold<double>(
                  0.0,
                  (sum, sec) => sum + sec.progressPercentage,
                ) /
                sections.length;

        currentLevelModules.add(LevelModule(
          id: modId,
          levelNumber: isFoundation ? 1 : appLevelIndex,
          moduleNumber: modNumber,
          moduleName: modTitle,
          courseTitle: modTitle,
          sections: sections,
          contentItems: const [],
          progressPercentage: totalProgress,
        ));
      }

      if (isFoundation) {
        // Collect modules from Foundation levels instead of creating a map entry
        foundationModules.addAll(currentLevelModules);
      } else {
        final int levelNumber = appLevelIndex++;
        final bool isFirstTrackLevel = levelNumber == 1;

        final List<LevelModule> finalModules = isFirstTrackLevel
            ? [...foundationModules, ...currentLevelModules]
            : currentLevelModules;

        levelDataList.add(LevelModulesData(
          levelNumber: levelNumber,
          levelTitle: levelTitle,
          modules: finalModules,
          isExamAvailable: true,
          examId: 'exam_$levelId',
          showCustomPreExam: false,
        ));
      }
    }

    return levelDataList;
  }
}
