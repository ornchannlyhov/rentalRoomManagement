import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/repositories/receipt_repository.dart';
import 'package:joul_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:joul_v2/presentation/view/screen/receipt/receipt_confirmation_screen.dart';
import 'package:joul_v2/core/services/local_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final ReceiptRepository _receiptRepository;
  final RepositoryManager? _repositoryManager;
  final GlobalKey<NavigatorState> navigatorKey;
  final ApiHelper _apiHelper = ApiHelper.instance;

  static const String _storageKey = 'notification_receipts';
  static const String _unreadKey = 'notification_unread';

  AsyncValue<List<Receipt>> _newReceipts = const AsyncValue.success([]);
  bool _hasUnread = false;
  bool _isInitialized = false;

  NotificationProvider(
    this._receiptRepository,
    this.navigatorKey, {
    RepositoryManager? repositoryManager,
  }) : _repositoryManager = repositoryManager;

  AsyncValue<List<Receipt>> get newReceipts => _newReceipts;
  bool get hasUnread => _hasUnread;
  int get unreadCount => _hasUnread ? (_newReceipts.data?.length ?? 0) : 0;

  /// Load persisted notifications from local storage
  Future<void> loadNotifications() async {
    if (_isInitialized) return;

    try {
      final receiptIdsJson = await _apiHelper.storage.read(key: _storageKey);
      final unreadStatus = await _apiHelper.storage.read(key: _unreadKey);

      if (receiptIdsJson != null && receiptIdsJson.isNotEmpty) {
        final receiptIds = List<String>.from(jsonDecode(receiptIdsJson));
        final allReceipts = _receiptRepository.getAllReceipts();

        final notificationReceipts = receiptIds
            .map((id) {
              try {
                return allReceipts.firstWhere((r) => r.id == id);
              } catch (_) {
                return null;
              }
            })
            .whereType<Receipt>()
            .toList();

        _newReceipts = AsyncValue.success(notificationReceipts);
        _hasUnread = unreadStatus == 'true';
      }
    } catch (_) {
      _newReceipts = const AsyncValue.success([]);
      _hasUnread = false;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Save notifications state persistently
  Future<void> _saveNotifications() async {
    try {
      final receiptIds = _newReceipts.data?.map((r) => r.id).toList() ?? [];
      await _apiHelper.storage.write(
        key: _storageKey,
        value: jsonEncode(receiptIds),
      );
      await _apiHelper.storage.write(
        key: _unreadKey,
        value: _hasUnread.toString(),
      );
    } catch (_) {}
  }

  /// Initialize Firebase listeners for notifications
  void setupListeners() {
    // Listen to local notification taps
    LocalNotificationService.onNotificationTap.listen((payload) {
      if (payload != null) {
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _handleReceiptNotification(data, showNavigation: true);
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
      }
    });

    // App opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['type'];
      if (type == 'NEW_RECEIPT' || type == 'NEW_USAGE_INPUT') {
        _handleReceiptNotification(message.data, showNavigation: true);
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
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _handleReceiptNotification(
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
      _newReceipts = AsyncValue.loading(_newReceipts.bestData ?? []);
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
        _newReceipts = AsyncValue.error(
          Exception('Receipt not found: $receiptId'),
          _newReceipts.previousData,
        );
        notifyListeners();
        return;
      }

      final currentList = _newReceipts.previousData ?? [];
      final exists = currentList.any((r) => r.id == receipt!.id);

      if (!exists) {
        _newReceipts = AsyncValue.success([receipt, ...currentList]);
        _hasUnread = true;
        await _saveNotifications();
      } else {
        _newReceipts = AsyncValue.success(currentList);
      }

      notifyListeners();

      if (showNavigation && navigatorKey.currentContext != null) {
        // Navigate to different screens based on notification type
        if (notificationType == 'NEW_USAGE_INPUT') {
          // Navigate to confirmation screen for usage inputs
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ReceiptConfirmationScreen(receipt: receipt!),
            ),
          );
        } else {
          // Default to detail screen for regular receipts
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ReceiptDetailScreen(receipt: receipt!),
            ),
          );
        }
      }
    } catch (e) {
      _newReceipts = AsyncValue.error(e, _newReceipts.previousData);
      notifyListeners();
    }
  }

  void markAsRead() {
    if (_hasUnread) {
      _hasUnread = false;
      _saveNotifications();
      notifyListeners();
    }
  }

  void clearNotifications() {
    _newReceipts = const AsyncValue.success([]);
    markAsRead();
    _saveNotifications();
  }

  void removeNotification(String receiptId) {
    final updatedList =
        (_newReceipts.data ?? []).where((r) => r.id != receiptId).toList();
    _newReceipts = AsyncValue.success(updatedList);
    if (updatedList.isEmpty) _hasUnread = false;
    _saveNotifications();
    notifyListeners();
  }
}
