class LevelModule {
  final String id;
  final int levelNumber;
  final int moduleNumber;
  final String moduleName;
  final String courseTitle;
  final List<ModuleSection> sections;
  final List<ModuleContentItem> contentItems;
  final double progressPercentage;
  final bool isExamPassed;
  final bool isFoundation;

  const LevelModule({
    required this.id,
    required this.levelNumber,
    required this.moduleNumber,
    required this.moduleName,
    required this.courseTitle,
    required this.sections,
    required this.contentItems,
    required this.progressPercentage,
    this.isExamPassed = false,
    this.isFoundation = false,
  });
}

class ModuleSection {
  final String id;
  final String title;
  final String description;
  final double progressPercentage;
  final bool isCompleted;

  const ModuleSection({
    required this.id,
    required this.title,
    required this.description,
    required this.progressPercentage,
    required this.isCompleted,
  });
}

class ModuleContentItem {
  final String id;
  final String title;
  final String contentType;
  final String meta;
  final bool isCompleted;

  /// The media URL for this content item (Supabase Storage URL, YouTube link, etc.).
  final String? mediaUrl;

  const ModuleContentItem({
    required this.id,
    required this.title,
    required this.contentType,
    required this.meta,
    required this.isCompleted,
    this.mediaUrl,
  });
}

class LevelModulesData {
  final int levelNumber;
  final String levelTitle;
  final List<LevelModule> modules;
  final bool isExamAvailable;
  final String examId;
  final bool showCustomPreExam;

  const LevelModulesData({
    required this.levelNumber,
    required this.levelTitle,
    required this.modules,
    required this.isExamAvailable,
    required this.examId,
    this.showCustomPreExam = false,
  });
}
