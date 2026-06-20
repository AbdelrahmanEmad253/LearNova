import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/island_map/data/datasources/island_map_remote_data_source.dart';
import 'package:learnova/features/island_map/data/repositories/island_map_repository_impl.dart';
import 'package:learnova/features/island_map/domain/entities/island_module.dart';
import 'package:learnova/features/island_map/domain/entities/topic.dart';
import 'package:learnova/features/island_map/domain/repositories/island_map_repository.dart';

// ── Data Sources ──
final islandMapRemoteDataSourceProvider =
    Provider<IslandMapRemoteDataSource>((ref) {
  return IslandMapRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ── Repository ──
final islandMapRepositoryProvider = Provider<IslandMapRepository>((ref) {
  return IslandMapRepositoryImpl(ref.watch(islandMapRemoteDataSourceProvider));
});

// ── Reactive Data ──

/// Fetches modules for a given level UUID.
final islandModulesProvider =
    FutureProvider.family<List<IslandModule>, String>((ref, levelId) {
  return ref.watch(islandMapRepositoryProvider).getModulesForLevel(levelId);
});

/// Fetches topics + filtered resources for a given module UUID.
/// Reads the user's learningStyle from the existing studentProfileProvider.
final moduleTopicsProvider =
    FutureProvider.family<List<Topic>, String>((ref, moduleId) async {
  final profile = ref.watch(studentProfileProvider).value;
  final style = profile?.learningStyle ?? profile?.effectiveVarkStyle ?? 'Visual';

  return ref
      .watch(islandMapRepositoryProvider)
      .getTopicsForModule(moduleId, learningStyle: style);
});
