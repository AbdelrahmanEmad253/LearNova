import 'package:learnova/features/auth/data/datasources/avatar_local_data_source.dart';
import 'package:learnova/features/auth/domain/entities/avatar_option.dart';
import 'package:learnova/features/auth/domain/repositories/avatar_repository.dart';

class AvatarRepositoryImpl implements AvatarRepository {
  final AvatarLocalDataSource localDataSource;

  const AvatarRepositoryImpl(this.localDataSource);

  @override
  List<AvatarOption> getAvatarOptions() {
    return localDataSource
        .getAvatarOptions()
        .map((optionModel) => optionModel.toEntity())
        .toList();
  }
}
