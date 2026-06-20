import 'package:learnova/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';
import 'package:learnova/features/assessment/domain/repositories/assessment_repository.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentRemoteDataSource remoteDataSource;

  const AssessmentRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AssessmentTest>> getAssessmentTests() async {
    final tests = await remoteDataSource.getAssessmentTests();
    return tests.map((testModel) => testModel.toEntity()).toList();
  }
}
