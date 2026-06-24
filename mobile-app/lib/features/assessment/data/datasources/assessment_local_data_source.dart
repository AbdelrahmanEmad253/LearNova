import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:learnova/core/data/local_cache_data_source.dart';

/// Local cache for assessment test data.
///
/// Stores the raw Supabase JSON response so it can be used as a fallback
/// when the device is offline or the request fails.
class AssessmentLocalDataSource {
  final LocalCacheDataSource _cache;

  static const String _cacheKey = 'cache.assessment_tests';
  static const Duration _cacheTtl = Duration(hours: 24);

  const AssessmentLocalDataSource(this._cache);

  /// Cache the raw assessment rows as JSON.
  Future<void> cacheTests(List<Map<String, dynamic>> rows) async {
    await _cache.putWithTtl(
      _cacheKey,
      jsonEncode(rows),
      _cacheTtl,
    );
  }

  /// Retrieve cached assessment rows.
  /// Returns null if no cache exists or it has expired.
  /// If [forceStale] is true, returns data even if expired (offline fallback).
  List<Map<String, dynamic>>? getCachedTests({bool forceStale = false}) {
    final jsonString = _cache.get(
      _cacheKey,
      ignoreExpiry: forceStale,
    );
    if (jsonString == null) return null;

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  /// Cache in-progress diagnostic answers.
  Future<void> cacheDiagnosticAnswers(String diagnosticTypeId, List<Map<String, dynamic>> answers) async {
    final key = 'cache.diagnostic_answers.$diagnosticTypeId';
    try {
      final encoded = jsonEncode(answers);
      await _cache.put(key, encoded);
      debugPrint('[AssessmentLocalDataSource] Cached ${answers.length} answers for $diagnosticTypeId');
    } catch (e) {
      debugPrint('[AssessmentLocalDataSource] Error encoding cached answers: $e');
    }
  }

  /// Retrieve cached in-progress diagnostic answers.
  List<Map<String, dynamic>>? getCachedDiagnosticAnswers(String diagnosticTypeId) {
    final key = 'cache.diagnostic_answers.$diagnosticTypeId';
    final jsonString = _cache.get(key);
    if (jsonString == null) {
      debugPrint('[AssessmentLocalDataSource] No cache found for $diagnosticTypeId');
      return null;
    }

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      final result = decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      debugPrint('[AssessmentLocalDataSource] Successfully loaded ${result.length} cached answers for $diagnosticTypeId');
      return result;
    } catch (e) {
      debugPrint('[AssessmentLocalDataSource] Error decoding cached answers for $diagnosticTypeId: $e');
      return null;
    }
  }

  /// Clear cached diagnostic answers (usually called upon successful submission).
  Future<void> clearCachedDiagnosticAnswers(String diagnosticTypeId) async {
    final key = 'cache.diagnostic_answers.$diagnosticTypeId';
    await _cache.remove(key);
  }
}
