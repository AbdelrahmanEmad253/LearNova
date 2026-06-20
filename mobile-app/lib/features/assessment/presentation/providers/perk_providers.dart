import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/assessment/data/datasources/perk_remote_data_source.dart';
import 'package:learnova/features/assessment/domain/entities/perk_state.dart';
import 'package:learnova/features/assessment/presentation/providers/perk_deck_viewmodel.dart';

// ── Data Source ──

final perkRemoteDataSourceProvider = Provider<PerkRemoteDataSource>((ref) {
  return PerkRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ── ViewModel ──
//
// One instance per exam session. Using `autoDispose` so the state is cleaned
// up when the exam screen is popped from the navigation stack.

final perkDeckViewModelProvider =
    StateNotifierProvider.autoDispose<PerkDeckViewModel, PerkDeckState>((ref) {
  final dataSource = ref.watch(perkRemoteDataSourceProvider);
  return PerkDeckViewModel(dataSource);
});
