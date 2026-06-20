import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for diagnostic test operations (questions, submissions, evidence).
///
/// Reads from the new `diagnostic_questions` table where each row has:
///   - `test_number` (1-5) to identify which diagnostic test it belongs to
///   - `question_key` (unique slug)
///   - `question_text` (the prompt shown to the student)
///   - `question_type` (e.g. 'mcq', 'scale', etc.)
///   - `options` (JSONB – the answer choices / scale labels)
///   - `order_index` (display order within the test)
class DiagnosticRemoteDataSource {
  final SupabaseClient _client;

  /// Maps the canonical test index (0-based, used by the assessment flow)
  /// to the `test_number` column (1-based) in the `diagnostic_questions` table.
  ///
  /// Index 0 → test_number 1 (IPIP Personality)
  /// Index 1 → test_number 2 (Soft Skills)
  /// Index 2 → test_number 3 (VARK Learning Style)
  /// Index 3 → test_number 4 (Career Interest)
  /// Index 4 → test_number 5 (IQ / Cognitive)
  static const List<String> diagnosticTypeIdsByIndex = <String>[
    'ipip_exam',
    'soft_skills_exam',
    'vark_exam',
    'career_interest_exam',
    'iq_exam',
  ];

  const DiagnosticRemoteDataSource(this._client);

  /// Returns the canonical test-type string for a given 0-based test index.
  String diagnosticTypeIdForTestIndex(int testIndex) {
    if (testIndex < 0) {
      return diagnosticTypeIdsByIndex.first;
    }
    return diagnosticTypeIdsByIndex[
        testIndex % diagnosticTypeIdsByIndex.length];
  }

  /// Converts a canonical diagnostic type ID to the 1-based `test_number`.
  int _testNumberFromTypeId(String diagnosticTestTypeId) {
    final idx = diagnosticTypeIdsByIndex.indexOf(diagnosticTestTypeId);
    // test_number is 1-based; default to 1 if not found.
    return idx >= 0 ? idx + 1 : 1;
  }

  Future<void> ensureDiagnosticSubmissionSession() async {
    final current = _client.auth.currentUser;
    if (current != null) return;

    try {
      final authResponse = await _client.auth.signInAnonymously();
      if (authResponse.user != null) return;
    } catch (_) {
      // If anonymous auth is disabled, caller gets an error below.
    }

    throw const AuthException(
      'No authenticated user found. Sign in is required before saving test results.',
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Diagnostic question fetching (new `diagnostic_questions` table)
  // ────────────────────────────────────────────────────────────────────────────

  String _buildPublicUrl(String bucket, String path) {
    // Sanitize path: remove leading slash if present
    String sanitizedPath = path.trim();
    if (sanitizedPath.startsWith('/')) {
      sanitizedPath = sanitizedPath.substring(1);
    }
    final url = _client.storage.from(bucket).getPublicUrl(sanitizedPath);
    debugPrint('[DiagnosticRDS] Generated Image URL: $url (Bucket: $bucket, Path: $sanitizedPath)');
    return url;
  }

  /// Fetches diagnostic questions from the `diagnostic_questions` table
  /// filtered by [diagnosticTestTypeId] (mapped to `test_number`).
  ///
  /// Also fetches associated images from `diagnostic_question_images` and
  /// attaches the first image URL (by `order_index`) to each question.
  ///
  /// Returns a list of maps with keys: `id`, `question`, `options`,
  /// and optionally `image_url` and `correct_answer_index`.
  Future<List<Map<String, dynamic>>> fetchDiagnosticQuestions(
    String diagnosticTestTypeId,
  ) async {
    final int testNumber = _testNumberFromTypeId(diagnosticTestTypeId);

    final raw = await _client
        .from('diagnostic_questions')
        .select('id, question_key, question_text, question_type, options, order_index')
        .eq('test_number', testNumber)
        .order('order_index');

    final rows = List<Map<String, dynamic>>.from(raw);

    if (rows.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    // Collect all question IDs to batch-fetch images.
    final questionIds = rows
        .map((r) => r['id']?.toString())
        .whereType<String>()
        .toList(growable: false);

    Map<String, String> imageUrlByQuestionId = <String, String>{};

    try {
      final imageRows = await _client
          .from('diagnostic_question_images')
          .select('question_id, storage_path, bucket, order_index')
          .inFilter('question_id', questionIds)
          .order('order_index');

      for (final imgRow in List<Map<String, dynamic>>.from(imageRows)) {
        final qId = imgRow['question_id']?.toString() ?? '';
        // Only keep the first image per question (lowest order_index).
        if (imageUrlByQuestionId.containsKey(qId)) continue;

        final bucket = imgRow['bucket']?.toString() ?? 'content-assets';
        final path = imgRow['storage_path']?.toString() ?? '';
        if (path.isNotEmpty) {
          imageUrlByQuestionId[qId] = _buildPublicUrl(bucket, path);
        }
      }
    } catch (e) {
      // Image table may not exist yet — gracefully continue without images.
      debugPrint('Error fetching images: $e');
    }

    return rows.map((row) {
      final mapped = _mapDiagnosticQuestionRow(row);
      if (mapped == null) return null;

      // Attach image URL from the images table if available.
      final qId = row['id']?.toString() ?? '';
      final imageUrl = imageUrlByQuestionId[qId];
      if (imageUrl != null && !mapped.containsKey('image_url')) {
        mapped['image_url'] = imageUrl;
      }

      return mapped;
    }).whereType<Map<String, dynamic>>().toList(growable: false);
  }

  /// Maps a single row from `diagnostic_questions` to the presentation format.
  ///
  /// The `options` JSONB has this shape:
  /// ```json
  /// {
  ///   "choices": [{"label": "...", "value": ...}, ...],
  ///   "answer_structure": { "correct_answer_value": "C", ... },
  ///   "media": { "public_url_template": "https://...", ... }   // optional
  /// }
  /// ```
  ///
  /// Returns a map with keys:
  ///   - `id`, `question`, `options` (list of label strings)
  ///   - `correct_answer_index` (int, if answer_structure.correct_answer_value exists)
  ///   - `image_url` (String?, if media.public_url_template exists)
  ///   - `choice_values` (list of raw values for scoring)
  Map<String, dynamic>? _mapDiagnosticQuestionRow(
    Map<String, dynamic> row,
  ) {
    final String? questionId = row['id']?.toString();
    final String? questionText = row['question_text']?.toString();

    if (questionId == null || questionText == null || questionText.isEmpty) {
      return null;
    }

    // Parse the `options` JSONB column.
    dynamic rawOptions = row['options'];

    if (rawOptions is String) {
      try {
        rawOptions = jsonDecode(rawOptions);
      } catch (_) {
        rawOptions = null;
      }
    }

    if (rawOptions is! Map<String, dynamic>) {
      return null;
    }

    final Map<String, dynamic> optionsMap = rawOptions;

    // ── Parse choices ──
    List<String> labels = <String>[];
    List<dynamic> values = <dynamic>[];

    final dynamic rawChoices = optionsMap['choices'];
    if (rawChoices is List) {
      for (final choice in rawChoices) {
        if (choice is Map<String, dynamic>) {
          final label = choice['label']?.toString();
          if (label != null && label.isNotEmpty) {
            labels.add(label);
            values.add(choice['value']);
          }
        } else if (choice is String) {
          labels.add(choice);
          values.add(choice);
        }
      }
    }

    if (labels.length < 2) {
      return null;
    }

    // ── Parse optional image media ──
    String? imageUrl;
    final dynamic media = optionsMap['media'];
    if (media is Map<String, dynamic>) {
      final bucket = media['bucket']?.toString() ?? 'content-assets';
      final path = media['storage_path']?.toString();
      
      // Check for template URL first
      final templateUrl = media['public_url_template']?.toString();
      if (templateUrl != null && templateUrl.contains('{{SUPABASE_URL}}')) {
        final baseUrl = _client.rest.url.replaceAll('/rest/v1', '');
        imageUrl = templateUrl.replaceAll('{{SUPABASE_URL}}', baseUrl);
        debugPrint('[DiagnosticRDS] Using Template URL: $imageUrl');
      } else if (path != null) {
        imageUrl = _buildPublicUrl(bucket, path);
      }
    }

    // ── Parse optional correct answer ──
    int? correctAnswerIndex;
    final dynamic answerStructure = optionsMap['answer_structure'];
    if (answerStructure is Map<String, dynamic>) {
      final correctValue = answerStructure['correct_answer_value'];
      if (correctValue != null) {
        final idx = values.indexWhere(
          (v) => v.toString() == correctValue.toString(),
        );
        if (idx >= 0) {
          correctAnswerIndex = idx;
        }
      }
    }

    final result = <String, dynamic>{
      'id': questionId,
      'question_key': row['question_key']?.toString(),
      'question': questionText,
      'options': labels,
      'choice_values': values,
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      result['image_url'] = imageUrl;
    }

    if (correctAnswerIndex != null) {
      result['correct_answer_index'] = correctAnswerIndex;
    }

    return result;
  }

  /// Submits the raw answers and diagnostic results to the new `diagnostic_test_results` table.
  /// [testNumber] is 1-5.
  /// [rawAnswers] can be a List or a Map (JSONB).
  Future<bool> submitDiagnosticResult({
    required int testNumber,
    required dynamic rawAnswers,
    Map<String, dynamic>? computedScores,
    double? externalScore,
    String resultSource = 'in_app',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    final row = <String, dynamic>{
      'user_id': user.id,
      'test_number': testNumber,
      'raw_answers': rawAnswers,
      'computed_scores': computedScores,
      'result_source': resultSource,
      'external_score': externalScore,
      'completed_at': DateTime.now().toIso8601String(),
    };

    try {
      // Use upsert to handle the unique constraint (user_id, test_number)
      await _client.from('diagnostic_test_results').upsert(
            row,
            onConflict: 'user_id, test_number',
          );
      return true;
    } on PostgrestException catch (e) {
      final details = [
        if (e.code != null && e.code!.isNotEmpty) 'code=${e.code}',
        if (e.message.isNotEmpty) e.message,
        if (e.details != null) e.details.toString(),
        if (e.hint != null && e.hint!.isNotEmpty) 'hint=${e.hint}',
      ].join(' | ');
      throw Exception('submitDiagnosticResult failed: $details');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Diagnostic submission (Legacy - for compatibility)
  // ────────────────────────────────────────────────────────────────────────────

  Future<bool> submitDiagnostic({
    required String testTypeId,
    required int quantitativeScore,
    int? submissionScore,
    String? resultLabel,
    String? externalProofImg,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    final row = <String, dynamic>{
      'user_id': user.id,
      'test_type_id': testTypeId,
      'result_label': resultLabel,
      'submission_score': submissionScore,
    };

    if (externalProofImg != null && externalProofImg.isNotEmpty) {
      row['external_proof_img'] = externalProofImg;
    } else {
      row['quantitative_score'] = quantitativeScore;
    }

    try {
      await _client.from('student_diagnostic_result').insert(row);
      return true;
    } on PostgrestException catch (e) {
      final details = [
        if (e.code != null && e.code!.isNotEmpty) 'code=${e.code}',
        if (e.message.isNotEmpty) e.message,
        if (e.details != null) e.details.toString(),
        if (e.hint != null && e.hint!.isNotEmpty) 'hint=${e.hint}',
      ].join(' | ');
      throw Exception('submitDiagnostic failed: $details');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Exam-specific question fetching (module quizzes via `question` table)
  // ────────────────────────────────────────────────────────────────────────────

  /// Fetches exam questions by [moduleId].
  /// Uses `module_assessments` and `module_assessment_questions` tables.
  Future<List<Map<String, dynamic>>> fetchExamQuestions(
    String moduleId,
  ) async {
    // 1. Find the assessment_id for this module
    final assessmentRes = await _client
        .from('module_assessments')
        .select('id')
        .eq('module_id', moduleId)
        .maybeSingle();

    if (assessmentRes == null) {
      return <Map<String, dynamic>>[];
    }
    
    final assessmentId = assessmentRes['id'];

    // 2. Fetch questions
    final raw = await _client
        .from('module_assessment_questions')
        .select('id, question_text, options, correct_answer, order_index')
        .eq('assessment_id', assessmentId)
        .order('order_index');

    final rows = List<Map<String, dynamic>>.from(raw);

    if (rows.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    // Fetch related images if any
    final questionIds = rows
        .map((r) => r['id']?.toString())
        .whereType<String>()
        .toList(growable: false);

    Map<String, String> imageUrlByQuestionId = <String, String>{};

    try {
      final imageRows = await _client
          .from('module_assessment_question_images')
          .select('question_id, storage_path, order_index')
          .inFilter('question_id', questionIds)
          .order('order_index');

      for (final imgRow in List<Map<String, dynamic>>.from(imageRows)) {
        final qId = imgRow['question_id']?.toString() ?? '';
        if (imageUrlByQuestionId.containsKey(qId)) continue;
        final bucket = 'content-assets';
        final path = imgRow['storage_path']?.toString() ?? '';
        if (path.isNotEmpty) {
          imageUrlByQuestionId[qId] = _buildPublicUrl(bucket, path);
        }
      }
    } catch (_) {
      // Image table might not exist or be empty
    }

    return rows.map((row) {
      final mapped = _mapExamQuestionRow(row);
      if (mapped == null) return null;
      final qId = row['id']?.toString() ?? '';
      final imageUrl = imageUrlByQuestionId[qId];
      if (imageUrl != null) {
        mapped['image_url'] = imageUrl;
      }
      return mapped;
    }).whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Map<String, dynamic>? _mapExamQuestionRow(
    Map<String, dynamic> row,
  ) {
    final String? questionId = row['id']?.toString();
    final String? questionText = row['question_text']?.toString();

    if (questionId == null || questionText == null) {
      return null;
    }

    List<String> options = <String>[];
    List<dynamic> choiceValues = <dynamic>[];

    dynamic rawOptions = row['options'];

    if (rawOptions is String) {
      try {
        rawOptions = jsonDecode(rawOptions);
      } catch (_) {
        // Fallback to raw if decoding fails
      }
    }

    if (rawOptions is List) {
      options = List<dynamic>.from(rawOptions)
          .map((e) => e.toString())
          .toList(growable: false);
      choiceValues = List<dynamic>.from(rawOptions);
    } else if (rawOptions is Map<String, dynamic>) {
      final choices = rawOptions['choices'];
      if (choices is List) {
        for (final choice in choices) {
          if (choice is Map<String, dynamic>) {
            final label = choice['label']?.toString();
            if (label != null) {
              options.add(label);
              choiceValues.add(choice['value']);
            }
          } else if (choice is String) {
            options.add(choice);
            choiceValues.add(choice);
          }
        }
      }
    }

    if (options.length < 2) {
      return null;
    }

    // ── Parse optional image media from options JSONB ──
    String? mediaImageUrl;
    if (rawOptions is Map<String, dynamic>) {
      final dynamic media = rawOptions['media'];
      if (media is Map<String, dynamic>) {
        final bucket = media['bucket']?.toString() ?? 'content-assets';
        final path = media['storage_path']?.toString();

        // Check for template URL first
        final templateUrl = media['public_url_template']?.toString();
        if (templateUrl != null && templateUrl.contains('{{SUPABASE_URL}}')) {
          final baseUrl = _client.rest.url.replaceAll('/rest/v1', '');
          mediaImageUrl = templateUrl.replaceAll('{{SUPABASE_URL}}', baseUrl);
          debugPrint('[DiagnosticRDS Exam] Using Template URL: $mediaImageUrl');
        } else if (path != null) {
          mediaImageUrl = _buildPublicUrl(bucket, path);
        }
      }
    }

    int correctAnswerIndex = 0;
    final correctAnswer = row['correct_answer']?.toString();
    if (correctAnswer != null) {
      // Try matching by value (new format)
      final valIdx =
          choiceValues.indexWhere((v) => v.toString() == correctAnswer);
      if (valIdx >= 0) {
        correctAnswerIndex = valIdx;
      } else {
        // Fallback to matching by label (legacy format)
        final lblIdx = options.indexOf(correctAnswer);
        if (lblIdx >= 0) {
          correctAnswerIndex = lblIdx;
        }
      }
    }

    return <String, dynamic>{
      'id': questionId,
      'question': questionText,
      'options': options,
      'correct_answer_index': correctAnswerIndex,
      if (mediaImageUrl != null) 'image_url': mediaImageUrl,
    };
  }

  Future<bool> submitModuleExamResult({
    required String moduleId,
    required double score,
    required bool passed,
    required String difficulty,
    required List<Map<String, dynamic>> answers,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    // 1. Find the assessment_id for this module
    final assessmentRes = await _client
        .from('module_assessments')
        .select('id')
        .eq('module_id', moduleId)
        .maybeSingle();

    if (assessmentRes == null) {
      return false;
    }
    
    final assessmentId = assessmentRes['id'];

    final row = <String, dynamic>{
      'user_id': user.id,
      'assessment_id': assessmentId,
      'answers': answers,
      'score': score,
      'passed': passed,
      'difficulty': difficulty,
      'submitted_at': DateTime.now().toIso8601String(),
    };

    try {
      await _client.from('student_module_attempts').insert(row);
      return true;
    } on PostgrestException catch (e) {
      final details = [
        if (e.code != null && e.code!.isNotEmpty) 'code=${e.code}',
        if (e.message.isNotEmpty) e.message,
        if (e.details != null) e.details.toString(),
        if (e.hint != null && e.hint!.isNotEmpty) 'hint=${e.hint}',
      ].join(' | ');
      throw Exception('submitModuleExamResult failed: $details');
    }
  }

  /// Returns a real-time stream of diagnostic results for the current user.
  Stream<List<Map<String, dynamic>>> diagnosticResultsStream() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _client
        .from('diagnostic_test_results')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('test_number');
  }
  Future<bool> submitExamResult({
    required String quizId,
    required int scorePercentage,
    required String resultLabel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not authenticated.');
    }

    final row = <String, dynamic>{
      'user_id': user.id,
      'test_type_id': quizId,
      'result_label': resultLabel,
      'submission_score': scorePercentage,
      'quantitative_score': scorePercentage,
    };

    try {
      await _client.from('student_diagnostic_result').insert(row);
      return true;
    } on PostgrestException catch (e) {
      final details = [
        if (e.code != null && e.code!.isNotEmpty) 'code=${e.code}',
        if (e.message.isNotEmpty) e.message,
        if (e.details != null) e.details.toString(),
        if (e.hint != null && e.hint!.isNotEmpty) 'hint=${e.hint}',
      ].join(' | ');
      throw Exception('submitExamResult failed: $details');
    }
  }
}
