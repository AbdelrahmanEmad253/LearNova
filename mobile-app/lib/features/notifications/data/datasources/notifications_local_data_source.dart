import 'package:learnova/features/notifications/data/datasources/notifications_cache.dart';
import 'package:learnova/features/notifications/data/models/notifications_data_model.dart';

class NotificationsLocalDataSource {
  final NotificationsCache cache;

  const NotificationsLocalDataSource(this.cache);

  NotificationsDataModel getNotificationsData() {
    return cache.getNotificationsData();
  }
}
