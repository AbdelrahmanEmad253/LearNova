import 'dart:convert';

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
}
