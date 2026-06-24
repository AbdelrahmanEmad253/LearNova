import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/notifications/data/datasources/notifications_cache.dart';
import 'package:learnova/features/notifications/data/datasources/notifications_local_data_source.dart';
import 'package:learnova/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';
import 'package:learnova/features/notifications/domain/usecases/get_notifications_data_usecase.dart';
import 'package:learnova/features/notifications/data/models/notifications_data_model.dart';

final notificationsCacheProvider = Provider<NotificationsCache>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  return NotificationsCache(ref.watch(sharedPreferencesProvider), userId: userId);
});

final notificationsDataProvider = StateNotifierProvider<NotificationsNotifier, NotificationsData>((ref) {
  final cache = ref.watch(notificationsCacheProvider);
  final useCase = GetNotificationsDataUseCase(
    NotificationsRepositoryImpl(NotificationsLocalDataSource(cache)),
  );
  return NotificationsNotifier(useCase, cache);
});

class NotificationsNotifier extends StateNotifier<NotificationsData> {
  final GetNotificationsDataUseCase _useCase;
  final NotificationsCache _cache;

  NotificationsNotifier(this._useCase, this._cache) : super(_useCase()) {
    refresh();
  }

  void refresh() {
    state = _useCase();
  }

  Future<void> addNotification(NotificationItemModel item) async {
    await _cache.addNotification(item);
    refresh();
  }

  Future<void> removeNotification(String id) async {
    await _cache.removeNotification(id);
    refresh();
  }

  Future<void> markAsRead(String id) async {
    await _cache.markAsRead(id);
    refresh();
  }
}
