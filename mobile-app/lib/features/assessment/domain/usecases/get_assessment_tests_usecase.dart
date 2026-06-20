import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';
import 'package:learnova/features/assessment/domain/repositories/assessment_repository.dart';

class GetAssessmentTestsUseCase {
  final AssessmentRepository repository;

  const GetAssessmentTestsUseCase(this.repository);

  Future<List<AssessmentTest>> call() {
    return repository.getAssessmentTests();
  }
}
