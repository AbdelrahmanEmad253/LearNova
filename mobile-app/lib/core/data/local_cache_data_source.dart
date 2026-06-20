import 'package:shared_preferences/shared_preferences.dart';

/// A generic JSON cache backed by [SharedPreferences].
///
/// Stores string data (typically JSON) with optional TTL (time-to-live)
/// support. Used for remote-first, local-fallback data fetching patterns.
class LocalCacheDataSource {
  final SharedPreferences _prefs;

  const LocalCacheDataSource(this._prefs);

  static const String _ttlSuffix = '__ttl_expiry';

  /// Store [jsonData] under [key] without expiry.
  Future<void> put(String key, String jsonData) async {
    await _prefs.setString(key, jsonData);
    // Remove any existing TTL marker.
    await _prefs.remove('$key$_ttlSuffix');
  }

  /// Store [jsonData] under [key] with a TTL.
  /// After [ttl] elapses, [get] will treat the data as stale and return null.
  Future<void> putWithTtl(String key, String jsonData, Duration ttl) async {
    await _prefs.setString(key, jsonData);
    final expiryMs =
        DateTime.now().add(ttl).millisecondsSinceEpoch;
    await _prefs.setInt('$key$_ttlSuffix', expiryMs);
  }

  /// Retrieve cached data for [key].
  ///
  /// Returns null if:
  /// - No data exists for [key]
  /// - The data has a TTL and it has expired
  ///
  /// If [ignoreExpiry] is true, returns data even if TTL has expired
  /// (useful as ultimate fallback when offline).
  String? get(String key, {bool ignoreExpiry = false}) {
    final data = _prefs.getString(key);
    if (data == null) return null;

    if (!ignoreExpiry) {
      final expiryMs = _prefs.getInt('$key$_ttlSuffix');
      if (expiryMs != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
        if (DateTime.now().isAfter(expiry)) {
          return null; // Stale
        }
      }
    }

    return data;
  }

  /// Check if non-expired data exists for [key].
  bool has(String key) => get(key) != null;

  /// Remove data and its TTL marker.
  Future<void> remove(String key) async {
    await _prefs.remove(key);
    await _prefs.remove('$key$_ttlSuffix');
  }
}
