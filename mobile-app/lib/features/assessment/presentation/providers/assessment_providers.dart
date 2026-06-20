import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/assessment/data/datasources/assessment_local_data_source.dart';
import 'package:learnova/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:learnova/features/assessment/data/datasources/diagnostic_remote_data_source.dart';
import 'package:learnova/features/assessment/data/repositories/assessment_repository_impl.dart';
import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';
import 'package:learnova/features/assessment/domain/repositories/assessment_repository.dart';
import 'package:learnova/features/assessment/domain/usecases/get_assessment_tests_usecase.dart';

// ── Data Sources ──

final assessmentLocalDataSourceProvider =
    Provider<AssessmentLocalDataSource>((ref) {
  return AssessmentLocalDataSource(ref.watch(localCacheDataSourceProvider));
});

final assessmentRemoteDataSourceProvider =
    Provider<AssessmentRemoteDataSource>((ref) {
  return AssessmentRemoteDataSource(
    ref.watch(supabaseClientProvider),
    ref.watch(assessmentLocalDataSourceProvider),
  );
});

final diagnosticRemoteDataSourceProvider =
    Provider<DiagnosticRemoteDataSource>((ref) {
  return DiagnosticRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ── Repository ──

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  return AssessmentRepositoryImpl(ref.watch(assessmentRemoteDataSourceProvider));
});

// ── Use Cases ──

final getAssessmentTestsUseCaseProvider =
    Provider<GetAssessmentTestsUseCase>((ref) {
  return GetAssessmentTestsUseCase(ref.watch(assessmentRepositoryProvider));
});

// ── Reactive State ──

final assessmentTestsProvider = FutureProvider<List<AssessmentTest>>((ref) {
  return ref.watch(getAssessmentTestsUseCaseProvider).call();
});

/// Real-time stream provider to fetch the results analyzed by Python.
final diagnosticResultsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final ds = ref.watch(diagnosticRemoteDataSourceProvider);
  return ds.diagnosticResultsStream();
});
