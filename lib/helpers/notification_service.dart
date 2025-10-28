import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    // Windows-compatible initialization
    final InitializationSettings initializationSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: const DarwinInitializationSettings(),
      // Add Windows settings to prevent the error
      windows: const WindowsInitializationSettings(
        appName: 'Receipts',
        appUserModelId: 'com.receipts.app',
        guid: '{00000000-0000-0000-0000-000000000000}'
      ),
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    // Only show notifications on supported platforms
    if (Platform.isAndroid || Platform.isIOS) {
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'receipt_channel',
          'Receipt Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _notificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
      );
    } else {
      // For Windows/Desktop, just print to console (or implement desktop notifications later)
      print('Notification: $title - $body');
    }
  }
}