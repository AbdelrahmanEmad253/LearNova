import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/notifications/data/datasources/notifications_local_data_source.dart';
import 'package:learnova/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';
import 'package:learnova/features/notifications/domain/usecases/get_notifications_data_usecase.dart';

final notificationsDataProvider = Provider<NotificationsData>((ref) {
  final useCase = GetNotificationsDataUseCase(
    const NotificationsRepositoryImpl(NotificationsLocalDataSource()),
  );
  return useCase();
});
