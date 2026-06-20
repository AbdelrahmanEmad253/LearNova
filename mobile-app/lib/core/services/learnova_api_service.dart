import 'package:supabase_flutter/supabase_flutter.dart';

class LearNovaApiException implements Exception {
  final String message;
  final Object? cause;
  LearNovaApiException(this.message, {this.cause});
  @override
  String toString() => 'LearNovaApiException: $message';
}

class MitchyChatResult {
  final String responseText;
  final String learningState;
  final double sentimentScore;
  final double cognitiveLoad;
  final String suggestedAction;
  final String recommendedFormat;
  final Map<String, dynamic> metadata;

  MitchyChatResult({
    required this.responseText,
    required this.learningState,
    required this.sentimentScore,
    required this.cognitiveLoad,
    required this.suggestedAction,
    required this.recommendedFormat,
    required this.metadata,
  });

  factory MitchyChatResult.fromJson(Map<String, dynamic> json) {
    return MitchyChatResult(
      responseText: json['response_text']?.toString() ?? '',
      learningState: json['learning_state']?.toString() ?? 'unknown',
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.0,
      cognitiveLoad: (json['cognitive_load'] as num?)?.toDouble() ?? 0.0,
      suggestedAction: json['suggested_action']?.toString() ?? 'none',
      recommendedFormat: json['recommended_format']?.toString() ?? 'textual',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? const {}),
    );
  }
}

class LearNovaApiService {
  final SupabaseClient _supabase;

  LearNovaApiService(this._supabase);

  void _ensureSignedIn() {
    if (_supabase.auth.currentSession == null) {
      throw LearNovaApiException('User must be signed in.');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw LearNovaApiException('Invalid backend response shape.');
  }

  void _ensureOk(Map<String, dynamic> data, String fallbackMessage) {
    if (data['ok'] != true) {
      throw LearNovaApiException(
        data['error']?.toString() ?? data['detail']?.toString() ?? fallbackMessage,
      );
    }
  }

  /// Sends a message to Mitchy AI via Edge Function.
  Future<MitchyChatResult> sendMitchyMessage({
    required String message,
    String? topicId,
    String? moduleId,
    String screenContext = 'unknown',
  }) async {
    _ensureSignedIn();
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      throw LearNovaApiException('Message cannot be empty.');
    }
    try {
      final response = await _supabase.functions.invoke(
        'mitchy-chat',
        body: {
          'message': cleanMessage,
          'topic_id': topicId,
          'module_id': moduleId,
          'screen_context': screenContext,
        },
      );
      final data = _asMap(response.data);
      _ensureOk(data, 'Mitchy failed');

      // Detect edge-function fallback responses and surface the reason
      final metadata = data['metadata'];
      if (metadata is Map && metadata['source'] == 'edge_fallback') {
        final reason = metadata['reason']?.toString() ?? 'unknown';
        throw LearNovaApiException(
          'Mitchy AI backend error: $reason',
        );
      }

      return MitchyChatResult.fromJson(data);
    } catch (error) {
      if (error is LearNovaApiException) rethrow;
      throw LearNovaApiException('Could not send message to Mitchy.', cause: error);
    }
  }

  /// Triggers the final scoring engine after diagnostic tests.
  Future<Map<String, dynamic>> runScoringEngine() async {
    _ensureSignedIn();
    try {
      final response = await _supabase.functions.invoke(
        'run-scoring-engine',
        body: {},
      );
      final data = _asMap(response.data);
      _ensureOk(data, 'Scoring failed');
      return data;
    } catch (error) {
      if (error is LearNovaApiException) rethrow;
      throw LearNovaApiException('Could not run scoring engine.', cause: error);
    }
  }

  /// Submits a module exam attempt.
  Future<Map<String, dynamic>> submitModuleAttempt({
    required String assessmentId,
    required Map<String, dynamic> answers,
  }) async {
    _ensureSignedIn();
    try {
      final response = await _supabase.functions.invoke(
        'submit-module-attempt',
        body: {
          'assessment_id': assessmentId,
          'answers': answers,
        },
      );
      final data = _asMap(response.data);
      _ensureOk(data, 'Module attempt failed');
      return data;
    } catch (error) {
      if (error is LearNovaApiException) rethrow;
      throw LearNovaApiException('Could not submit module attempt.', cause: error);
    }
  }

  /// Uses a perk during a module exam.
  ///
  /// [perkType] must be `'owl_hint'` or `'sly_fox'`.
  /// Returns the full response map including `ok`, `hint`,
  /// `eliminated_option_index`, and `remaining`.
  Future<Map<String, dynamic>> usePerk({
    required String perkType,
    required String questionId,
  }) async {
    _ensureSignedIn();
    try {
      final response = await _supabase.functions.invoke(
        'use-perk',
        body: {
          'perk_type': perkType,
          'question_id': questionId,
        },
      );
      final data = _asMap(response.data);
      _ensureOk(data, 'Perk use failed');
      return data;
    } catch (error) {
      if (error is LearNovaApiException) rethrow;
      throw LearNovaApiException('Could not use perk.', cause: error);
    }
  }

  /// Submits a weekly challenge attempt.
  Future<Map<String, dynamic>> submitChallengeAttempt({
    required String challengeId,
    required Map<String, dynamic> answers,
  }) async {
    _ensureSignedIn();
    try {
      final response = await _supabase.functions.invoke(
        'submit-challenge-attempt',
        body: {
          'challenge_id': challengeId,
          'answers': answers,
        },
      );
      final data = _asMap(response.data);
      _ensureOk(data, 'Challenge attempt failed');
      return data;
    } catch (error) {
      if (error is LearNovaApiException) rethrow;
      throw LearNovaApiException('Could not submit challenge attempt.', cause: error);
    }
  }
}
