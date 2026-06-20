import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/features/assessment/data/datasources/assessment_local_data_source.dart';
import 'package:learnova/features/assessment/data/models/assessment_test_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssessmentRemoteDataSource {
  final SupabaseClient _client;
  final AssessmentLocalDataSource? _localCache;

  const AssessmentRemoteDataSource(this._client, [this._localCache]);

  /// Ordered IDs matching the canonical diagnostic test ordering.
  static const List<String> _diagnosticTypeIdsByIndex = <String>[
    'ipip_exam',
    'soft_skills_exam',
    'vark_exam',
    'career_interest_exam',
    'iq_exam',
  ];

  /// Fallback data used when Supabase is unreachable or returns empty.
  static final List<Map<String, dynamic>> _fallbackData = [
    {
      'id': 'career_interest_exam',
      'title': 'Career Interest Assessment',
      'metric_type': 'career_interest',
      'official_external_url': 'https://onetinterestprofiler.org/'
    },
    {
      'id': 'ipip_exam',
      'title': 'IPIP-NEO Personality Test (120 Items)',
      'metric_type': 'personality',
      'official_external_url': 'https://personality.co/...'
    },
    {
      'id': 'iq_exam',
      'title': 'Cognitive IQ Exam',
      'metric_type': 'cognitive',
      'official_external_url': 'https://www.yourselfirst.com/iq/quiz'
    },
    {
      'id': 'soft_skills_exam',
      'title': 'Soft Skills Assessment',
      'metric_type': 'sjt',
      'official_external_url': 'https://www.123test.com/...'
    },
    {
      'id': 'vark_exam',
      'title': 'Learning Style Assessment (VARK)',
      'metric_type': 'learning_style',
      'official_external_url': 'https://vark-learn.com/...'
    },
  ];

  Future<List<AssessmentTestModel>> getAssessmentTests() async {
    List<Map<String, dynamic>> rows;

    try {
      final raw = await _client
          .from('diagnostic_test_type')
          .select('id, title, metric_type, official_external_url')
          .order('id')
          .timeout(const Duration(seconds: 5));

      rows = List<Map<String, dynamic>>.from(raw);
      if (rows.isEmpty) {
        rows = _fallbackData;
      } else {
        // Cache the fresh data from Supabase.
        _localCache?.cacheTests(rows);
      }
    } catch (_) {
      // Try local cache first, then hardcoded fallback.
      rows = _localCache?.getCachedTests(forceStale: true) ?? _fallbackData;
    }

    final ordered = _orderTests(rows);
    return ordered
        .map((row) => _toAssessmentTestModel(row))
        .whereType<AssessmentTestModel>()
        .toList(growable: false);
  }

  // ── Private helpers ──

  static List<Map<String, dynamic>> _orderTests(
      List<Map<String, dynamic>> rows) {
    final byId = <String, Map<String, dynamic>>{
      for (final row in rows)
        if (row['id'] != null) row['id'].toString(): row,
    };

    final orderedPreferred = _diagnosticTypeIdsByIndex
        .map((id) => byId[id])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    if (orderedPreferred.isNotEmpty) {
      return orderedPreferred;
    }
    return rows;
  }

  AssessmentTestModel? _toAssessmentTestModel(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final title = row['title']?.toString() ?? '';
    final metricType = row['metric_type']?.toString() ?? '';

    final resolvedType = _resolveType(id, metricType, title);

    if (resolvedType == null) {
      return AssessmentTestModel(
        id: id.isNotEmpty ? id : 'generic_test',
        title: title.isNotEmpty ? title : 'General Assessment',
        description:
            'A comprehensive evaluation to help guide your learning journey.',
        resultTitle: 'Analyzed',
        resultDescription:
            'Your results show high potential in various areas:',
        iconPath: AppAssets.testIconMind,
        topSvgPath: AppAssets.testCognTop,
        backgroundImagePath: AppAssets.testCognBg,
      );
    }

    switch (resolvedType) {
      case 'career_interest_exam':
        return AssessmentTestModel(
          id: 'career_interest_exam',
          title: title.isNotEmpty ? title : 'Career Interest Assessment',
          description:
              'Explore your interests to discover the career paths and work environments that suit you best.',
          resultTitle: 'Astute',
          resultDescription:
              'Test results that your analytical status describes you at best as:',
          iconPath: AppAssets.testIconMind,
          topSvgPath: AppAssets.testCognTop,
          backgroundImagePath: AppAssets.testCognBg,
        );
      case 'ipip_exam':
        return AssessmentTestModel(
          id: 'ipip_exam',
          title: title.isNotEmpty
              ? title
              : 'IPIP-NEO Personality Test (120 Items)',
          description:
              'Understand your personality traits and how they shape your decisions, communication, and work style.',
          resultTitle: 'Adaptive',
          resultDescription:
              'Test results that your social status describes you at best as:',
          iconPath: AppAssets.testIconSoft,
          topSvgPath: AppAssets.testSoftTop,
          backgroundImagePath: AppAssets.testSoftBg,
        );
      case 'iq_exam':
        return AssessmentTestModel(
          id: 'iq_exam',
          title: title.isNotEmpty ? title : 'Cognitive IQ Exam',
          description:
              'Measure core reasoning abilities such as pattern recognition, logic, and problem-solving speed.',
          resultTitle: 'Curious',
          resultDescription:
              'Test results that your behavioral status describes you at best as:',
          iconPath: AppAssets.testIconPersonal,
          topSvgPath: AppAssets.testPersonalTop,
          backgroundImagePath: AppAssets.testPersonalBg,
        );
      case 'soft_skills_exam':
        return AssessmentTestModel(
          id: 'soft_skills_exam',
          title: title.isNotEmpty ? title : 'Soft Skills Assessment',
          description:
              'Evaluate interpersonal and workplace behaviors including communication, teamwork, and adaptability.',
          resultTitle: 'Adaptive',
          resultDescription:
              'Test results that your learning preference describes you at best as:',
          iconPath: AppAssets.testIconLearn,
          topSvgPath: AppAssets.testLearnTop,
          backgroundImagePath: AppAssets.testLearnBg,
        );
      case 'vark_exam':
        return AssessmentTestModel(
          id: 'vark_exam',
          title: title.isNotEmpty ? title : 'Learning Style Assessment (VARK)',
          description:
              'Identify how you prefer to learn so your study approach can be personalized for better outcomes.',
          resultTitle: 'Strategic',
          resultDescription:
              'Test results that your professional path describes you at best as:',
          iconPath: AppAssets.testIconCareer,
          topSvgPath: AppAssets.testCareerTop,
          backgroundImagePath: AppAssets.testCareerBg,
        );
      default:
        return null;
    }
  }

  String? _resolveType(String id, String metricType, String title) {
    final normalizedId = id.toLowerCase();
    final normalizedMetric = metricType.toLowerCase();
    final normalizedTitle = title.toLowerCase();

    if (normalizedId.contains('career') ||
        normalizedMetric == 'career_interest' ||
        normalizedTitle.contains('career')) {
      return 'career_interest_exam';
    }

    if (normalizedId.contains('ipip') ||
        normalizedMetric == 'personality' ||
        normalizedTitle.contains('personality')) {
      return 'ipip_exam';
    }

    if (normalizedId.contains('iq') ||
        normalizedMetric == 'cognitive' ||
        normalizedTitle.contains('iq') ||
        normalizedTitle.contains('cognitive')) {
      return 'iq_exam';
    }

    if (normalizedId.contains('soft') ||
        normalizedMetric == 'sjt' ||
        normalizedTitle.contains('soft')) {
      return 'soft_skills_exam';
    }

    if (normalizedId.contains('vark') ||
        normalizedMetric == 'learning_style' ||
        normalizedTitle.contains('learning style') ||
        normalizedTitle.contains('vark')) {
      return 'vark_exam';
    }

    return null;
  }
}
