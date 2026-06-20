import 'package:learnova/features/notifications/data/datasources/notifications_local_data_source.dart';
import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';
import 'package:learnova/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsLocalDataSource localDataSource;

  const NotificationsRepositoryImpl(this.localDataSource);

  @override
  NotificationsData getNotificationsData() {
    return localDataSource.getNotificationsData().toEntity();
  }
}

