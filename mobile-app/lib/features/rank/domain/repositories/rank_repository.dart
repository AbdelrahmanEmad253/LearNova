import 'package:learnova/features/rank/domain/entities/rank_data.dart';

abstract class RankRepository {
  Future<RankData> getRankData();
}

