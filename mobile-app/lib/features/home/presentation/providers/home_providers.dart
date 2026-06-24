import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/home/data/datasources/level_modules_local_data_source.dart';
import 'package:learnova/features/home/data/datasources/map_levels_local_data_source.dart';
import 'package:learnova/features/home/data/datasources/module_content_remote_data_source.dart';
import 'package:learnova/features/home/data/datasources/global_map_remote_data_source.dart';
import 'package:learnova/features/home/data/repositories/level_modules_repository_impl.dart';
import 'package:learnova/features/home/data/repositories/map_levels_repository_impl.dart';
import 'package:learnova/features/content/domain/entities/lesson_topic.dart';
import 'package:learnova/features/home/domain/entities/map_level.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:learnova/features/home/domain/repositories/level_modules_repository.dart';
import 'package:learnova/features/home/domain/repositories/map_levels_repository.dart';
import 'package:learnova/features/home/domain/usecases/get_level_modules_usecase.dart';
import 'package:learnova/features/home/domain/usecases/get_map_levels_usecase.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';

// ── Data Sources ──

final mapLevelsLocalDataSourceProvider = Provider<MapLevelsLocalDataSource>((ref) {
  return const MapLevelsLocalDataSource();
});

final globalMapRemoteDataSourceProvider = Provider<GlobalMapRemoteDataSource>((ref) {
  return GlobalMapRemoteDataSource(ref.watch(supabaseClientProvider));
});

final moduleContentRemoteDataSourceProvider =
    Provider<ModuleContentRemoteDataSource>((ref) {
  return ModuleContentRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ── Repository ──

final mapLevelsRepositoryProvider = Provider<MapLevelsRepository>((ref) {
  return MapLevelsRepositoryImpl(ref.watch(mapLevelsLocalDataSourceProvider));
});

final levelModulesLocalDataSourceProvider =
    Provider<LevelModulesLocalDataSource>((ref) {
  return LevelModulesLocalDataSourceImpl();
});

final levelModulesRepositoryProvider = Provider<LevelModulesRepository>((ref) {
  return LevelModulesRepositoryImpl(
    ref.watch(levelModulesLocalDataSourceProvider),
  );
});

// ── Use Cases ──

final getMapLevelsUseCaseProvider = Provider<GetMapLevelsUseCase>((ref) {
  return GetMapLevelsUseCase(ref.watch(mapLevelsRepositoryProvider));
});

final getLevelModulesUseCaseProvider = Provider<GetLevelModulesUseCase>((ref) {
  return GetLevelModulesUseCase(ref.watch(levelModulesRepositoryProvider));
});

// ── Reactive Data ──

final mapLevelsProvider = Provider<List<MapLevel>>((ref) {
  return ref.watch(getMapLevelsUseCaseProvider).call();
});

/// Dynamically fetches lesson topics for a specific module from Supabase.
/// Falls back to an empty list on error — callers should use local data as fallback.
final moduleLessonTopicsProvider =
    FutureProvider.family<List<LessonTopic>, String>((ref, moduleId) {
  return ref
      .watch(moduleContentRemoteDataSourceProvider)
      .getLessonTopicsForModule(moduleId);
});

final globalMapProvider = FutureProvider<List<LevelModulesData>>((ref) async {
  final profile = ref.watch(studentProfileProvider).value;
  final track = profile?.assignedTrack ?? 'Foundation';
  final data =
      await ref.read(globalMapRemoteDataSourceProvider).getGlobalMapData(track);

  // Sync completed nodes to the unlock tracker.
  // GATE: A module only unlocks the next one when the user has PASSED its exam.
  final List<String> completedNodeIds = [];
  for (final level in data) {
    for (int i = 0; i < level.modules.length; i++) {
      final module = level.modules[i];

      // Only mark a node as "passed" if the exam was passed — this gates progression.
      if (module.isExamPassed) {
        completedNodeIds.add('w${level.levelNumber}_l${i + 1}');
      }

      // Sync individual topic completions to moduleProgressProvider
      final moduleCompletedTopics = module.sections
          .where((s) => s.isCompleted)
          .map((s) => s.id)
          .toList();
      if (moduleCompletedTopics.isNotEmpty) {
        ref.read(moduleProgressProvider.notifier).syncCompletedItems(
              moduleId: module.id,
              itemIds: moduleCompletedTopics,
            );
      }
    }
  }

  if (completedNodeIds.isNotEmpty) {
    ref.read(mapUnlockProvider.notifier).syncCompletedNodes(completedNodeIds);
  }

  return data;
});

/// Dynamically builds the progression order from the actual map data.
/// This ensures there are no gaps (e.g., if a level has only 3 modules).
final progressionOrderProvider = Provider<List<String>>((ref) {
  final mapData = ref.watch(globalMapProvider).value ?? [];
  final List<String> order = [];
  for (final level in mapData) {
    for (int i = 0; i < level.modules.length; i++) {
      order.add('w${level.levelNumber}_l${i + 1}');
    }
    if (level.isExamAvailable) {
      order.add('w${level.levelNumber}_e');
    }
  }
  return order;
});

// ──────────────────────────────────────────────────────────────────────────────
// Map Level Unlock State (replaces static MapLevelUnlockTracker)
// Persists passed node IDs to SharedPreferences for cold restart recovery.
// ──────────────────────────────────────────────────────────────────────────────

class MapUnlockNotifier extends Notifier<Set<String>> {
  String get _storageKey {
    final session = ref.read(authSessionStreamProvider).value;
    final userId = session?.userId ?? 'anonymous';
    return 'progress.map_unlock_passed_nodes_$userId';
  }

  @override
  Set<String> build() {
    // Watch session stream to automatically re-run build when user changes
    ref.watch(authSessionStreamProvider);
    return _loadFromPrefs();
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Set<String> _loadFromPrefs() {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return <String>{};
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _persistToPrefs(Set<String> data) async {
    await _prefs.setString(_storageKey, jsonEncode(data.toList()));
  }

  /// Merges externally fetched progress (from Supabase) into the local tracker.
  void syncCompletedNodes(List<String> nodeIds) {
    final Set<String> updated = {...state, ...nodeIds};
    if (updated.length > state.length) {
      state = updated;
      _persistToPrefs(updated);
    }
  }

  /// Returns `true` if [nodeId] is unlocked.
  bool isUnlocked(String nodeId) {
    if (state.contains(nodeId)) return true; // Already passed nodes are unlocked

    final order = ref.read(progressionOrderProvider);
    final index = order.indexOf(nodeId);
    
    if (index == 0) return true; // The very first node is always unlocked
    if (index == -1) return false; // Unknown nodes are locked by default

    // Unlocked if the immediate previous node in the progression has been passed
    final prevNode = order[index - 1];
    final unlocked = state.contains(prevNode);
    debugPrint('[MapUnlock] Checking "$nodeId": prev "$prevNode" passed? $unlocked');
    return unlocked;
  }

  /// Mark a node as passed, potentially unlocking the next node.
  void markPassed(String nodeId) {
    final order = ref.read(progressionOrderProvider);
    if (order.contains(nodeId)) {
      final updated = {...state, nodeId};
      state = updated;
      _persistToPrefs(updated);
    }
  }

  /// Returns the node that must be passed before [nodeId] is unlocked.
  String? requiredNodeToUnlock(String nodeId) {
    final order = ref.read(progressionOrderProvider);
    final index = order.indexOf(nodeId);
    if (index <= 0) return null;
    return order[index - 1];
  }

  /// Human-readable label for a given [nodeId].
  String labelForNode(String nodeId) {
    final examMatch = RegExp(r'^w(\d+)_e$').firstMatch(nodeId);
    if (examMatch != null) {
      return 'Level ${examMatch.group(1)} Exam';
    }

    final levelMatch = RegExp(r'^w(\d+)_l(\d+)$').firstMatch(nodeId);
    if (levelMatch != null) {
      return 'Level ${levelMatch.group(1)} - Module ${levelMatch.group(2)}';
    }

    return nodeId;
  }
}

final mapUnlockProvider =
    NotifierProvider<MapUnlockNotifier, Set<String>>(MapUnlockNotifier.new);

// ──────────────────────────────────────────────────────────────────────────────
// Module Progress State (replaces static ModuleProgressTracker)
// Persists completed item IDs per module to SharedPreferences.
// ──────────────────────────────────────────────────────────────────────────────

class ModuleProgressNotifier extends Notifier<Map<String, Set<String>>> {
  String get _storageKey {
    final session = ref.read(authSessionStreamProvider).value;
    final userId = session?.userId ?? 'anonymous';
    return 'progress.module_completed_items_$userId';
  }

  @override
  Map<String, Set<String>> build() {
    // Watch session stream to automatically re-run build when user changes
    ref.watch(authSessionStreamProvider);
    return _loadFromPrefs();
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Map<String, Set<String>> _loadFromPrefs() {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return <String, Set<String>>{};
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final items = (value as List<dynamic>).map((e) => e.toString()).toSet();
        return MapEntry(key, items);
      });
    } catch (_) {
      return <String, Set<String>>{};
    }
  }

  Future<void> _persistToPrefs(Map<String, Set<String>> data) async {
    final serializable = data.map(
      (key, value) => MapEntry(key, value.toList()),
    );
    await _prefs.setString(_storageKey, jsonEncode(serializable));
  }

  /// Merges completed item/topic IDs from Supabase into the local state.
  void syncCompletedItems({required String moduleId, required List<String> itemIds}) {
    final current = Map<String, Set<String>>.from(state);
    final existingItems = current[moduleId] ?? <String>{};
    final updatedItems = {...existingItems, ...itemIds};
    
    if (updatedItems.length > existingItems.length) {
      current[moduleId] = updatedItems;
      state = current;
      _persistToPrefs(current);
    }
  }

  /// Mark single content item as completed within a module.
  void markItemCompleted({required String moduleId, required String itemId}) {
    final current = Map<String, Set<String>>.from(state);
    current.putIfAbsent(moduleId, () => <String>{});
    current[moduleId] = {...current[moduleId]!, itemId};
    state = current;
    _persistToPrefs(current);
  }

  /// Check whether a specific item has been completed.
  bool isItemCompleted({required String moduleId, required String itemId}) {
    return state[moduleId]?.contains(itemId) ?? false;
  }

  /// Returns the set of completed item IDs for a module.
  Set<String> moduleProgress(String moduleId) {
    return state[moduleId] ?? const <String>{};
  }
}

final moduleProgressProvider =
    NotifierProvider<ModuleProgressNotifier, Map<String, Set<String>>>(
  ModuleProgressNotifier.new,
);

/// Provider to control the visibility of the bottom navigation bar during the initial map animation.
final isMapAnimatingProvider = StateProvider<bool>((ref) => true);

