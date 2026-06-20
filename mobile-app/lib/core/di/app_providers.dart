import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learnova/core/data/local_cache_data_source.dart';
import 'package:learnova/core/services/supabase/supabase_config.dart';
import 'package:learnova/core/services/learnova_api_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

final learnovaApiServiceProvider = Provider<LearNovaApiService>((ref) {
  return LearNovaApiService(ref.watch(supabaseClientProvider));
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope.',
  );
});

final localCacheDataSourceProvider = Provider<LocalCacheDataSource>((ref) {
  return LocalCacheDataSource(ref.watch(sharedPreferencesProvider));
});
