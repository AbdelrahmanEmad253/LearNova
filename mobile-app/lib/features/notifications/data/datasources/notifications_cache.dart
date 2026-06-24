import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnova/features/notifications/data/models/notifications_data_model.dart';

class NotificationsCache {
  final String _key;
  final SharedPreferences _prefs;

  NotificationsCache(this._prefs, {String? userId}) 
      : _key = userId != null && userId.isNotEmpty ? 'cached_notifications_data_$userId' : 'cached_notifications_data';

  NotificationsDataModel getNotificationsData() {
    final String? jsonString = _prefs.getString(_key);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return NotificationsDataModel.fromJson(jsonMap);
      } catch (e) {
        // Fallback on error
      }
    }

    // Default empty state
    return const NotificationsDataModel(
      screenTitle: 'Notifications',
      headline: 'Stay updated',
      subtitle: 'Your latest progress, rewards, and reminders all in one place.',
      items: [],
    );
  }

  Future<void> saveNotificationsData(NotificationsDataModel data) async {
    final String jsonString = jsonEncode(data.toJson());
    await _prefs.setString(_key, jsonString);
  }

  Future<void> addNotification(NotificationItemModel item) async {
    final currentData = getNotificationsData();
    final updatedItems = List<NotificationItemModel>.from(currentData.items);
    
    // Add to top of list
    updatedItems.insert(0, item);
    
    // Optional: limit to 50 notifications
    if (updatedItems.length > 50) {
      updatedItems.removeLast();
    }

    final updatedData = NotificationsDataModel(
      screenTitle: currentData.screenTitle,
      headline: currentData.headline,
      subtitle: currentData.subtitle,
      items: updatedItems,
    );
    
    await saveNotificationsData(updatedData);
  }

  Future<void> removeNotification(String id) async {
    final currentData = getNotificationsData();
    final updatedItems = currentData.items.where((item) => item.id != id).toList();
    
    final updatedData = NotificationsDataModel(
      screenTitle: currentData.screenTitle,
      headline: currentData.headline,
      subtitle: currentData.subtitle,
      items: updatedItems,
    );
    
    await saveNotificationsData(updatedData);
  }

  Future<void> markAsRead(String id) async {
    final currentData = getNotificationsData();
    final updatedItems = currentData.items.map((item) {
      if (item.id == id) {
        return NotificationItemModel(
          id: item.id,
          title: item.title,
          description: item.description,
          createdAt: item.createdAt,
          deeplink: item.deeplink,
          isUnread: false,
        );
      }
      return item;
    }).toList();
    
    final updatedData = NotificationsDataModel(
      screenTitle: currentData.screenTitle,
      headline: currentData.headline,
      subtitle: currentData.subtitle,
      items: updatedItems,
    );
    
    await saveNotificationsData(updatedData);
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
