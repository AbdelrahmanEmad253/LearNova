import 'package:learnova/features/rank/domain/entities/rank_data.dart';
import 'package:learnova/features/rank/domain/repositories/rank_repository.dart';

class GetRankDataUseCase {
  final RankRepository repository;

  const GetRankDataUseCase(this.repository);

  Future<RankData> call() async {
    return await repository.getRankData();
  }
}

