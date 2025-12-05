import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/data/models/notification_item.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/repositories/notification_repository.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:joul_v2/presentation/view/screen/receipt/receipt_confirmation_screen.dart';
import 'package:joul_v2/core/services/local_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final ReceiptRepository _receiptRepository;
  final NotificationRepository _notificationRepository;
  final RepositoryManager? _repositoryManager;
  final GlobalKey<NavigatorState> navigatorKey;

  AsyncValue<List<NotificationItem>> _notifications =
      const AsyncValue.success([]);
  bool _isInitialized = false;

  NotificationProvider(
    this._receiptRepository,
    this._notificationRepository,
    this.navigatorKey, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<NotificationItem>> get notifications => _notifications;
  bool get hasUnread => _notificationRepository.hasUnread;
  int get unreadCount => _notificationRepository.unreadCount;
  List<NotificationItem> get notificationList =>
      _notificationRepository.notifications;

  /// Load persisted notifications from Hive
  Future<void> loadNotifications() async {
    if (_isInitialized) return;

    try {
      await _notificationRepository.load();
      _notifications =
          AsyncValue.success(_notificationRepository.notifications);
    } catch (_) {
      _notifications = const AsyncValue.success([]);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Get receipt for a notification (convenience method)
  Receipt? getReceiptForNotification(NotificationItem notification) {
    if (notification.receiptId == null) return null;
    final allReceipts = _receiptRepository.getAllReceipts();
    try {
      return allReceipts.firstWhere((r) => r.id == notification.receiptId);
    } catch (_) {
      return null;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAsRead(notificationId);
    _notifications = AsyncValue.success(_notificationRepository.notifications);
    notifyListeners();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _notificationRepository.markAllAsRead();
    _notifications = AsyncValue.success(_notificationRepository.notifications);
    notifyListeners();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteNotification(notificationId);
    _notifications = AsyncValue.success(_notificationRepository.notifications);
    notifyListeners();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationRepository.clear();
    _notifications = const AsyncValue.success([]);
    notifyListeners();
  }

  /// Sets up listeners for Firebase messages
  void setupListeners() {
    // Handle local notification taps
    LocalNotificationService.onNotificationTap.listen((payload) {
      if (payload != null) {
        try {
          final data = jsonDecode(payload);
          final type = data['type'];
          if (type == 'NEW_RECEIPT' || type == 'NEW_USAGE_INPUT') {
            _handleReceiptNotification(data, showNavigation: true);
          } else if (type == 'PAYMENT_RECEIVED') {
            _handlePaymentReceivedNotification(data, showNavigation: true);
          }
        } catch (e) {
          print('Error parsing notification payload: $e');
        }
      }
    });

    // Show notification when app is open (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final type = message.data['type'];
      if (type == 'NEW_RECEIPT' || type == 'NEW_USAGE_INPUT') {
        _handleReceiptNotification(message.data, showNavigation: false);
        _showForegroundNotification(message);
      } else if (type == 'PAYMENT_RECEIVED') {
        _handlePaymentReceivedNotification(message.data, showNavigation: false);
        _showForegroundNotification(message);
      }
    });

    // App opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['type'];
      if (type == 'NEW_RECEIPT' || type == 'NEW_USAGE_INPUT') {
        _handleReceiptNotification(message.data, showNavigation: true);
      } else if (type == 'PAYMENT_RECEIVED') {
        _handlePaymentReceivedNotification(message.data, showNavigation: true);
      }
    });

    _handleInitialMessage();
  }

  /// Show local notification when app is in foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'New Receipt';
    final body =
        message.notification?.body ?? 'You have received a new receipt';

    // Pass data as payload for tap handling
    final payload = jsonEncode(message.data);

    await LocalNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Handles notification when app launches from terminated state
  Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    final type = initialMessage?.data['type'];
    if (type == 'NEW_RECEIPT' || type == 'NEW_USAGE_INPUT') {
      // Delay slightly to ensure navigation is ready
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _handleReceiptNotification(
          initialMessage!.data,
          showNavigation: true,
        ),
      );
    } else if (type == 'PAYMENT_RECEIVED') {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _handlePaymentReceivedNotification(
          initialMessage!.data,
          showNavigation: true,
        ),
      );
    }
  }

  Future<void> _handleReceiptNotification(
    Map<String, dynamic> data, {
    required bool showNavigation,
  }) async {
    final receiptId = data['receiptId'];
    final notificationType = data['type'];
    if (receiptId == null) return;

    try {
      _notifications =
          AsyncValue.loading(_notificationRepository.notifications);
      notifyListeners();

      await _receiptRepository.syncFromApi();

      // Hydrate relationships after sync
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final allReceipts = _receiptRepository.getAllReceipts();
      Receipt? receipt;
      try {
        receipt = allReceipts.firstWhere((r) => r.id == receiptId);
      } catch (_) {
        // Receipt not found after sync, exit early
        _notifications =
            AsyncValue.success(_notificationRepository.notifications);
        notifyListeners();
        return;
      }

      // Create notification item and save to Hive
      final notificationItem = NotificationItem(
        id: '${notificationType}_${receiptId}_${DateTime.now().millisecondsSinceEpoch}',
        type: notificationType ?? 'NEW_RECEIPT',
        title: notificationType == 'NEW_USAGE_INPUT'
            ? 'Usage Input Required'
            : 'New Receipt',
        message: notificationType == 'NEW_USAGE_INPUT'
            ? 'Please input meter readings for ${receipt.room?.roomNumber ?? 'your room'}'
            : 'New receipt for ${receipt.room?.roomNumber ?? 'your room'}',
        receiptId: receiptId,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _notificationRepository.addNotification(notificationItem);
      _notifications =
          AsyncValue.success(_notificationRepository.notifications);
      notifyListeners();

      if (showNavigation && navigatorKey.currentContext != null) {
        if (notificationType == 'NEW_USAGE_INPUT') {
          // Navigate to usage input screen
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ReceiptConfirmationScreen(receipt: receipt!),
            ),
          );
        } else {
          // Navigate to receipt detail screen
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ReceiptDetailScreen(receipt: receipt!),
            ),
          );
        }
      }
    } catch (e) {
      _notifications =
          AsyncValue.success(_notificationRepository.notifications);
      notifyListeners();
    }
  }

  Future<void> _handlePaymentReceivedNotification(
    Map<String, dynamic> data, {
    required bool showNavigation,
  }) async {
    final receiptId = data['receiptId'];
    if (receiptId == null) return;

    try {
      _notifications =
          AsyncValue.loading(_notificationRepository.notifications);
      notifyListeners();

      // Sync to get updated receipt with paid status
      await _receiptRepository.syncFromApi();

      // Hydrate relationships after sync
      if (_repositoryManager != null) {
        await _repositoryManager.hydrateAllRelationships();
        await _repositoryManager.saveAll();
      }

      final allReceipts = _receiptRepository.getAllReceipts();
      Receipt? receipt;
      try {
        receipt = allReceipts.firstWhere((r) => r.id == receiptId);
      } catch (_) {
        // Receipt not found after sync, exit early
        _notifications =
            AsyncValue.success(_notificationRepository.notifications);
        notifyListeners();
        return;
      }

      // Create notification item and save to Hive
      final notificationItem = NotificationItem(
        id: 'PAYMENT_RECEIVED_${receiptId}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'PAYMENT_RECEIVED',
        title: 'Payment Received',
        message: 'Payment received for ${receipt.room?.roomNumber ?? 'a room'}',
        receiptId: receiptId,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _notificationRepository.addNotification(notificationItem);
      _notifications =
          AsyncValue.success(_notificationRepository.notifications);
      notifyListeners();

      if (showNavigation && navigatorKey.currentContext != null) {
        // Navigate to receipt detail screen to show the paid receipt
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ReceiptDetailScreen(receipt: receipt!),
          ),
        );
      }
    } catch (e) {
      _notifications =
          AsyncValue.success(_notificationRepository.notifications);
      notifyListeners();
    }
  }
}
