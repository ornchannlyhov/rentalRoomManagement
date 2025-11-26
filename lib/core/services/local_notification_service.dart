import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final Logger _logger = Logger();
  static bool _initialized = false;
  static final _onNotificationTapStream = StreamController<String?>.broadcast();
  static Stream<String?> get onNotificationTap =>
      _onNotificationTapStream.stream;

  /// Initialize local notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android initialization
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          _onNotificationTapStream.add(response.payload);
        },
      );

      _initialized = true;
      _logger.i('Local notifications initialized');
    } catch (e) {
      _logger.e('Failed to initialize local notifications: $e');
    }
  }

  /// Show a local notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'receipt_channel',
        'Receipt Notifications',
        channelDescription: 'Notifications for new receipts and usage inputs',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      _logger.i('Local notification shown: $title');
    } catch (e) {
      _logger.e('Failed to show local notification: $e');
    }
  }

  /// Cancel a specific notification
  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
