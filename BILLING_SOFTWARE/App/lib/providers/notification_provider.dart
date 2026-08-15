import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../core/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications(ApiService apiService) async {
    _isLoading = true;
    notifyListeners();

    final remote = await apiService.getNotifications();
    if (remote.isNotEmpty) {
      _notifications = remote;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(ApiService apiService, String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
    await apiService.markNotificationRead(id);
  }

  Future<void> markAllAsRead(ApiService apiService) async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await apiService.markAllNotificationsRead();
  }

  void addNotification(NotificationItem item) {
    _notifications.insert(0, item);
    notifyListeners();
  }
}
