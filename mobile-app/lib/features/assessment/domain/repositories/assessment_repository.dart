import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';

abstract class AssessmentRepository {
  Future<List<AssessmentTest>> getAssessmentTests();
}
