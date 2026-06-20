import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';
import 'package:learnova/features/notifications/domain/repositories/notifications_repository.dart';

class GetNotificationsDataUseCase {
  final NotificationsRepository repository;

  const GetNotificationsDataUseCase(this.repository);

  NotificationsData call() {
    return repository.getNotificationsData();
  }
}

