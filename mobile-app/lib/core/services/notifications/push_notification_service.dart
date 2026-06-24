import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:entrig/entrig.dart';
import 'package:learnova/core/navigation/main_navigation_screen.dart';
import 'package:learnova/features/notifications/data/models/notifications_data_model.dart';
import 'package:learnova/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:learnova/features/notifications/presentation/screens/notifications_screen.dart';

class PushNotificationService {
  static late final ProviderContainer _container;
  static late final GlobalKey<NavigatorState> _navigatorKey;

  static Future<void> initialize(
    ProviderContainer container,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    _container = container;
    _navigatorKey = navigatorKey;

    await Entrig.init(
      apiKey: const String.fromEnvironment(
        'ENTRIG_API_KEY',
        defaultValue: 'sk-proj-968ade16-e489964d29f49629d4082b4fd3ac744b20691be9786d48bc491fb3e497bef893',
      ),
      showForegroundNotification: true, // Show banner even when app is open
    );

    Entrig.onNotificationOpened.listen(_handleNotificationOpened);
    Entrig.foregroundNotifications.listen(_saveNotificationToCache);
  }

  static void _saveNotificationToCache(dynamic event) {
    String? dl;
    try { dl = event.deeplink?.toString(); } catch (_) {}
    dl ??= event.data?['deeplink']?.toString();
    try { dl ??= event.type?.toString(); } catch (_) {}

    _container.read(notificationsDataProvider.notifier).addNotification(
      NotificationItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: event.title ?? 'New Notification',
        description: event.body ?? '',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        deeplink: dl,
        isUnread: true,
      ),
    );
  }

  static void _handleNotificationOpened(dynamic event) {
    // Save to cache first
    _saveNotificationToCache(event);

    final context = _navigatorKey.currentContext;
    if (context != null) {
      String dl = '';
      try { dl = event.deeplink?.toString().toLowerCase() ?? ''; } catch (_) {}
      if (dl.isEmpty) dl = event.data?['deeplink']?.toString().toLowerCase() ?? '';
      try { if (dl.isEmpty) dl = event.type?.toString().toLowerCase() ?? ''; } catch (_) {}
      
      debugPrint('Opened notification: ${event.type}, extracted dl: $dl');

      if (dl.contains('leaderboard')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 3)));
      } else if (dl.contains('notifications')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      } else if (dl.contains('map')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)));
      } else if (dl.contains('challenge') || dl.contains('daily')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 1)));
      } else if (dl.contains('chat') || dl.contains('mitchy')) {
        final contentStr = event.data?['content']?.toString() ?? event.body?.toString() ?? '';
        if (contentStr.isNotEmpty) {
          // No need to inject manually; the chat screen fetches history automatically
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 2)));
      } else if (dl.contains('profile')) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 4)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)));
      }
    }
  }
}
