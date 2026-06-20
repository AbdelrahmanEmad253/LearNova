import 'package:learnova/features/home/data/models/level_module_model.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';

abstract class LevelModulesLocalDataSource {
  LevelModulesDataModel getLevelModules(int levelNumber);
}

class LevelModulesLocalDataSourceImpl extends LevelModulesLocalDataSource {
  LevelModulesLocalDataSourceImpl();

  @override
  LevelModulesDataModel getLevelModules(int levelNumber) {
    const int moduleCount = 3;

    final List<LevelModuleModel> allModules = [
      LevelModuleModel(
        id: 'da_l${levelNumber}_m1',
        levelNumber: levelNumber,
        moduleNumber: 1,
        moduleName: 'Module 1',
        courseTitle: 'The Engine (Math)',
        sections: [
          ModuleSectionModel(
            id: 'w${levelNumber}_l1_s1',
            title: 'Linear Algebra (Vectors)',
            description: 'Skill track',
            progressPercentage: (levelNumber == 1) ? 0.47 : 0.0,
            isCompleted: levelNumber > 1,
          ),
          ModuleSectionModel(
            id: 'w${levelNumber}_l1_s2',
            title: 'Calculus (Gradients)',
            description: 'Skill track',
            progressPercentage: (levelNumber == 1) ? 0.24 : 0.0,
            isCompleted: false,
          ),
        ],
        contentItems: [
          ModuleContentItemModel(
            id: 'w${levelNumber}_l1_c1',
            title: 'Linear Algebra (Vectors)',
            contentType: 'video',
            meta: '4:25',
            isCompleted: false,
          ),
          ModuleContentItemModel(
            id: 'w${levelNumber}_l1_c2',
            title: 'Calculus (Gradients)',
            contentType: 'text',
            meta: '16 Pages',
            isCompleted: false,
          ),
        ],
        progressPercentage: (levelNumber == 1) ? 0.33 : 0.0,
      ),
      LevelModuleModel(
        id: 'da_l${levelNumber}_m2',
        levelNumber: levelNumber,
        moduleNumber: 2,
        moduleName: 'Module 2',
        courseTitle: 'Advanced Concepts',
        sections: [
          ModuleSectionModel(
            id: 'w${levelNumber}_l2_s1',
            title: 'Matrix Operations',
            description: 'Skill track',
            progressPercentage: 0.0,
            isCompleted: false,
          ),
          ModuleSectionModel(
            id: 'w${levelNumber}_l2_s2',
            title: 'Differential Equations',
            description: 'Skill track',
            progressPercentage: 0.0,
            isCompleted: false,
          ),
        ],
        contentItems: [
          ModuleContentItemModel(
            id: 'w${levelNumber}_l2_c1',
            title: 'Matrix Operations',
            contentType: 'video',
            meta: '6:10',
            isCompleted: false,
          ),
          ModuleContentItemModel(
            id: 'w${levelNumber}_l2_c2',
            title: 'Differential Equations',
            contentType: 'article',
            meta: '12 Pages',
            isCompleted: false,
          ),
        ],
        progressPercentage: 0.0,
      ),
      LevelModuleModel(
        id: 'da_l${levelNumber}_m3',
        levelNumber: levelNumber,
        moduleNumber: 3,
        moduleName: 'Module 3',
        courseTitle: 'Applied Mathematics',
        sections: [
          ModuleSectionModel(
            id: 'w${levelNumber}_l3_s1',
            title: 'Real-world Applications',
            description: 'Skill track',
            progressPercentage: 0.0,
            isCompleted: false,
          ),
          ModuleSectionModel(
            id: 'w${levelNumber}_l3_s2',
            title: 'Problem Solving',
            description: 'Skill track',
            progressPercentage: 0.0,
            isCompleted: false,
          ),
        ],
        contentItems: [
          ModuleContentItemModel(
            id: 'w${levelNumber}_l3_c1',
            title: 'Real-world Applications',
            contentType: 'audio',
            meta: '9:40',
            isCompleted: false,
          ),
          ModuleContentItemModel(
            id: 'w${levelNumber}_l3_c2',
            title: 'Problem Solving',
            contentType: 'text',
            meta: '10 Pages',
            isCompleted: false,
          ),
        ],
        progressPercentage: 0.0,
      ),
    ];

    return LevelModulesDataModel(
      levelNumber: levelNumber,
      levelTitle: 'Level $levelNumber',
      modules: allModules.take(moduleCount).toList().cast<LevelModule>(),
      isExamAvailable: true,
      examId: 'w${levelNumber}_e',
      showCustomPreExam: true,
    );
  }
}
