/// ECO Wallet — Notification Provider
import 'package:flutter/material.dart';
import '../core/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    try {
      final res = await ApiService.get('/notifications?limit=30');
      if (res['success'] == true) {
        _notifications = List<Map<String, dynamic>>.from(res['data']['notifications']);
        _unreadCount = res['data']['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await ApiService.get('/notifications/unread-count');
      if (res['success'] == true) {
        _unreadCount = res['data']['count'] ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiService.put('/notifications/$id/read');
      final idx = _notifications.indexWhere((n) => n['id'].toString() == id);
      if (idx != -1) {
        _notifications[idx]['read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.put('/notifications/read-all');
      for (var n in _notifications) {
        n['read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
