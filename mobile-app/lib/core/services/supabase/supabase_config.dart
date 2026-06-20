import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralised Supabase bootstrapping.
///
/// URL and anon-key are injected at build time via `--dart-define`:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://cdywjepxzqslgwsxyxcv.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// For CI / staging builds, set the corresponding env vars in your pipeline.
class SupabaseConfig {
  // Fall back to the existing project values when dart-defines are absent
  // (e.g. during local `flutter run` without flags).
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cdywjepxzqslgwsxyxcv.supabase.co',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkeXdqZXB4enFzbGd3c3h5eGN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MTUxMDAsImV4cCI6MjA5Mzk5MTEwMH0.mT7UJM2JCDsfQiLaAstPMR7dZKo5ZztVhFuQbL2QMnc',
  );

  /// Initialize Supabase with proper configuration.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Get the Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}
