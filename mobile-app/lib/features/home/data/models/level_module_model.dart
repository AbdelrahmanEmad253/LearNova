import 'package:learnova/features/home/domain/entities/level_module.dart';

class LevelModuleModel extends LevelModule {
  const LevelModuleModel({
    required super.id,
    required super.levelNumber,
    required super.moduleNumber,
    required super.moduleName,
    required super.courseTitle,
    required super.sections,
    required super.contentItems,
    required super.progressPercentage,
  });

  factory LevelModuleModel.fromJson(Map<String, dynamic> json) {
    return LevelModuleModel(
      id: json['id'] as String,
      levelNumber: json['levelNumber'] as int,
      moduleNumber: json['moduleNumber'] as int,
      moduleName: json['moduleName'] as String,
      courseTitle: json['courseTitle'] as String,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => ModuleSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      contentItems: (json['contentItems'] as List<dynamic>)
          .map(
              (e) => ModuleContentItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      progressPercentage: json['progressPercentage'] as double,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'levelNumber': levelNumber,
        'moduleNumber': moduleNumber,
        'moduleName': moduleName,
        'courseTitle': courseTitle,
        'sections':
            sections.map((e) => (e as ModuleSectionModel).toJson()).toList(),
        'contentItems': contentItems
            .map((e) => (e as ModuleContentItemModel).toJson())
            .toList(),
        'progressPercentage': progressPercentage,
      };
}

class ModuleSectionModel extends ModuleSection {
  const ModuleSectionModel({
    required super.id,
    required super.title,
    required super.description,
    required super.progressPercentage,
    required super.isCompleted,
  });

  factory ModuleSectionModel.fromJson(Map<String, dynamic> json) {
    return ModuleSectionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      progressPercentage: json['progressPercentage'] as double,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'progressPercentage': progressPercentage,
        'isCompleted': isCompleted,
      };
}

class ModuleContentItemModel extends ModuleContentItem {
  const ModuleContentItemModel({
    required super.id,
    required super.title,
    required super.contentType,
    required super.meta,
    required super.isCompleted,
    super.mediaUrl,
  });

  factory ModuleContentItemModel.fromJson(Map<String, dynamic> json) {
    return ModuleContentItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      contentType: json['contentType'] ?? json['content_type'] as String,
      meta: json['meta'] ?? '',
      isCompleted: json['isCompleted'] ?? json['is_completed'] ?? false,
      mediaUrl: json['mediaUrl'] ?? json['media_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'contentType': contentType,
        'meta': meta,
        'isCompleted': isCompleted,
        'mediaUrl': mediaUrl,
      };
}

class LevelModulesDataModel extends LevelModulesData {
  const LevelModulesDataModel({
    required super.levelNumber,
    required super.levelTitle,
    required super.modules,
    required super.isExamAvailable,
    required super.examId,
    required super.showCustomPreExam,
  });

  factory LevelModulesDataModel.fromJson(Map<String, dynamic> json) {
    return LevelModulesDataModel(
      levelNumber: json['levelNumber'] as int,
      levelTitle: json['levelTitle'] as String,
      modules: (json['modules'] as List<dynamic>)
          .map((e) => LevelModuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isExamAvailable: json['isExamAvailable'] as bool,
      examId: json['examId'] as String,
      showCustomPreExam: json['showCustomPreExam'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'levelTitle': levelTitle,
        'modules':
            modules.map((e) => (e as LevelModuleModel).toJson()).toList(),
        'isExamAvailable': isExamAvailable,
        'examId': examId,
        'showCustomPreExam': showCustomPreExam,
      };
}
