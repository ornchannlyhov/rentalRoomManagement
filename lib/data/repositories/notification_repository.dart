import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/services/database_service.dart';
import 'package:joul_v2/data/dtos/notification_item_dto.dart';
import 'package:joul_v2/data/models/notification_item.dart';

class NotificationRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  List<NotificationItem> _notificationCache = [];
  bool _hasUnread = false;
  int _unreadCount = 0;

  NotificationRepository(this._databaseService);

  List<NotificationItem> get notifications =>
      List.unmodifiable(_notificationCache);
  bool get hasUnread => _hasUnread;
  int get unreadCount => _unreadCount;

  /// Load notifications from Hive (local cache)
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
      _unreadCount = _notificationCache.where((n) => !n.isRead).length;

      if (kDebugMode) {
        print('📬 Loaded ${_notificationCache.length} notifications from Hive');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      _notificationCache = [];
      _hasUnread = false;
      _unreadCount = 0;
    }
  }

  /// Save notifications to Hive (local cache)
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

  /// Sync notifications from backend API
  /// This fetches all notifications from the server and updates local cache
  Future<void> syncFromApi() async {
    if (!await _apiHelper.hasNetwork()) {
      if (kDebugMode) {
        print('📬 No network available for notification sync');
      }
      return;
    }

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) {
      if (kDebugMode) {
        print('📬 No auth token available for notification sync');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print(
            '📬 Syncing notifications from ${_apiHelper.baseUrl}/notifications');
      }
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/notifications',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (kDebugMode) {
        print('📬 Notification sync response: ${response.statusCode}');
        print('📬 Notification sync data: ${response.data}');
      }

      if (response.data['cancelled'] == true) {
        return;
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> notificationsJson = response.data['data'] ?? [];
        _unreadCount = response.data['unreadCount'] ?? 0;

        _notificationCache = notificationsJson.map((json) {
          if (kDebugMode) {
            print('📬 Parsing notification: $json');
          }
          final dto = NotificationItemDto.fromJson(json);
          return dto.toModel();
        }).toList();

        // Sort by createdAt descending (newest first)
        _notificationCache.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Update hasUnread based on server data
        _hasUnread = _unreadCount > 0;

        // Save to local cache
        await save();

        if (kDebugMode) {
          print(
              '📬 Synced ${_notificationCache.length} notifications from API (unread: $_unreadCount)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notifications from API: $e');
      }
      // Don't throw - keep existing cache
    }
  }

  /// Add a new notification (local only - server pushes create notifications)
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
    _unreadCount = _notificationCache.where((n) => !n.isRead).length;
    await save();
  }

  /// Mark a notification as read (syncs to backend)
  Future<void> markAsRead(String notificationId) async {
    final index = _notificationCache.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    // Update local cache first for immediate UI feedback
    _notificationCache[index] =
        _notificationCache[index].copyWith(isRead: true);
    _hasUnread = _notificationCache.any((n) => !n.isRead);
    _unreadCount = _notificationCache.where((n) => !n.isRead).length;
    await save();

    // Sync to backend
    await _markAsReadOnServer(notificationId);
  }

  /// Mark a notification as read on the server
  Future<void> _markAsReadOnServer(String notificationId) async {
    if (!await _apiHelper.hasNetwork()) return;

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      await _apiHelper.dio.put(
        '${_apiHelper.baseUrl}/notifications/$notificationId/read',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (kDebugMode) {
        print('📬 Marked notification $notificationId as read on server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read on server: $e');
      }
      // Don't throw - local change is already saved
    }
  }

  /// Mark all notifications as read (syncs to backend)
  Future<void> markAllAsRead() async {
    // Update local cache first for immediate UI feedback
    for (var i = 0; i < _notificationCache.length; i++) {
      _notificationCache[i] = _notificationCache[i].copyWith(isRead: true);
    }
    _hasUnread = false;
    _unreadCount = 0;
    await save();

    // Sync to backend
    await _markAllAsReadOnServer();
  }

  /// Mark all notifications as read on the server
  Future<void> _markAllAsReadOnServer() async {
    if (!await _apiHelper.hasNetwork()) return;

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      await _apiHelper.dio.put(
        '${_apiHelper.baseUrl}/notifications/read-all',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (kDebugMode) {
        print('📬 Marked all notifications as read on server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read on server: $e');
      }
      // Don't throw - local change is already saved
    }
  }

  /// Delete a notification (syncs to backend)
  Future<void> deleteNotification(String notificationId) async {
    // Update local cache first for immediate UI feedback
    _notificationCache.removeWhere((n) => n.id == notificationId);
    _hasUnread = _notificationCache.any((n) => !n.isRead);
    _unreadCount = _notificationCache.where((n) => !n.isRead).length;
    await save();

    // Sync to backend
    await _deleteNotificationOnServer(notificationId);
  }

  /// Delete a notification on the server
  Future<void> _deleteNotificationOnServer(String notificationId) async {
    if (!await _apiHelper.hasNetwork()) return;

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      await _apiHelper.dio.delete(
        '${_apiHelper.baseUrl}/notifications/$notificationId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (kDebugMode) {
        print('📬 Deleted notification $notificationId on server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification on server: $e');
      }
      // Don't throw - local change is already saved
    }
  }

  /// Clear all notifications (syncs to backend)
  Future<void> clear() async {
    _notificationCache.clear();
    _hasUnread = false;
    _unreadCount = 0;
    await _databaseService.notificationsBox.clear();

    // Sync to backend
    await _clearAllOnServer();
  }

  /// Clear all notifications on the server
  Future<void> _clearAllOnServer() async {
    if (!await _apiHelper.hasNetwork()) return;

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) return;

    try {
      await _apiHelper.dio.delete(
        '${_apiHelper.baseUrl}/notifications',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (kDebugMode) {
        print('📬 Cleared all notifications on server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all notifications on server: $e');
      }
      // Don't throw - local change is already saved
    }
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
}
