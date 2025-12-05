import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/services/database_service.dart';
import 'package:joul_v2/data/dtos/notification_item_dto.dart';
import 'package:joul_v2/data/models/notification_item.dart';

class NotificationRepository {
  final DatabaseService _databaseService;
  List<NotificationItem> _notificationCache = [];
  bool _hasUnread = false;

  NotificationRepository(this._databaseService);

  List<NotificationItem> get notifications =>
      List.unmodifiable(_notificationCache);
  bool get hasUnread => _hasUnread;

  /// Load notifications from Hive
  Future<void> load() async {
    try {
      final notificationsList =
          _databaseService.notificationsBox.values.toList();
      _notificationCache = notificationsList.map((e) {
        final dto = NotificationItemDto.fromJson(Map<String, dynamic>.from(e));
        return dto.toModel();
      }).toList();

      // Sort by createdAt descending (newest first)
      _notificationCache.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Check for unread notifications
      _hasUnread = _notificationCache.any((n) => !n.isRead);

      if (kDebugMode) {
        print('📬 Loaded ${_notificationCache.length} notifications from Hive');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      _notificationCache = [];
      _hasUnread = false;
    }
  }

  /// Save notifications to Hive
  Future<void> save() async {
    try {
      await _databaseService.notificationsBox.clear();
      for (var i = 0; i < _notificationCache.length; i++) {
        final dto = NotificationItemDto.fromModel(_notificationCache[i]);
        await _databaseService.notificationsBox.put(i, dto.toJson());
      }

      if (kDebugMode) {
        print('📬 Saved ${_notificationCache.length} notifications to Hive');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notifications: $e');
      }
    }
  }

  /// Add a new notification
  Future<void> addNotification(NotificationItem notification) async {
    // Check if notification already exists
    final exists = _notificationCache.any((n) => n.id == notification.id);
    if (exists) {
      // Update existing notification
      final index =
          _notificationCache.indexWhere((n) => n.id == notification.id);
      _notificationCache[index] = notification;
    } else {
      // Add new notification at the beginning
      _notificationCache.insert(0, notification);
    }

    _hasUnread = _notificationCache.any((n) => !n.isRead);
    await save();
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notificationCache.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notificationCache[index] =
          _notificationCache[index].copyWith(isRead: true);
      _hasUnread = _notificationCache.any((n) => !n.isRead);
      await save();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notificationCache.length; i++) {
      _notificationCache[i] = _notificationCache[i].copyWith(isRead: true);
    }
    _hasUnread = false;
    await save();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    _notificationCache.removeWhere((n) => n.id == notificationId);
    _hasUnread = _notificationCache.any((n) => !n.isRead);
    await save();
  }

  /// Clear all notifications
  Future<void> clear() async {
    _notificationCache.clear();
    _hasUnread = false;
    await _databaseService.notificationsBox.clear();
  }

  /// Get notification by ID
  NotificationItem? getNotificationById(String id) {
    try {
      return _notificationCache.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get notifications by type
  List<NotificationItem> getNotificationsByType(String type) {
    return _notificationCache.where((n) => n.type == type).toList();
  }

  /// Get unread count
  int get unreadCount => _notificationCache.where((n) => !n.isRead).length;
}
