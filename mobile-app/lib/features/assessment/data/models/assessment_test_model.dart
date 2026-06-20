import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';

class AssessmentTestModel {
  final String id;
  final String title;
  final String description;
  final String resultTitle;
  final String resultDescription;
  final String iconPath;
  final String topSvgPath;
  final String backgroundImagePath;

  const AssessmentTestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.resultTitle,
    required this.resultDescription,
    required this.iconPath,
    required this.topSvgPath,
    required this.backgroundImagePath,
  });

  AssessmentTest toEntity() {
    return AssessmentTest(
      id: id,
      title: title,
      description: description,
      resultTitle: resultTitle,
      resultDescription: resultDescription,
      iconPath: iconPath,
      topSvgPath: topSvgPath,
      backgroundImagePath: backgroundImagePath,
    );
  }
}
