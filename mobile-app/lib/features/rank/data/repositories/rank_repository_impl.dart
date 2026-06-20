import 'package:learnova/features/rank/data/datasources/rank_local_data_source.dart';
import 'package:learnova/features/rank/domain/entities/rank_data.dart';
import 'package:learnova/features/rank/domain/repositories/rank_repository.dart';

class RankRepositoryImpl implements RankRepository {
  final RankLocalDataSource localDataSource;

  const RankRepositoryImpl(this.localDataSource);

  @override
  Future<RankData> getRankData() async {
    final model = await localDataSource.getRankData();
    return model.toEntity();
  }
}

