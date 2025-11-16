import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:logger/logger.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final AuthRepository _authRepository = AuthRepository();
  static final Logger _logger = Logger();

  /// Initialize FCM and upload token to backend (call AFTER login/register)
  static Future<void> initialize() async {
    try {
      // 1. Request notification permissions
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _logger.w('Notification permission denied');
        return;
      }

      // 2. Get device token with retry logic
      final String? token = await _getTokenWithRetry();
      if (token == null || token.isEmpty) {
        _logger.w('Failed to get FCM token after retries');
        return;
      }

      _logger.i('FCM token obtained: ${token.substring(0, 20)}...');

      // 3. Upload token to backend (silently fail if offline/error)
      try {
        await _authRepository.updateFCMToken(token);
        _logger.i('FCM token uploaded successfully');
      } catch (e) {
        _logger.e('Failed to upload FCM token: $e');
        // Don't throw - FCM is not critical for app functionality
      }
    } catch (e) {
      _logger.e('FCM initialization error: $e');
    }
  }

  /// Get FCM token with retry logic (sometimes it's null on first try)
  static Future<String?> _getTokenWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final String? token = await _messaging.getToken();

        if (token != null && token.isNotEmpty) {
          return token;
        }

        _logger.w('FCM token is null, retry ${i + 1}/$maxRetries');

        // Wait before retrying (exponential backoff)
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      } catch (e) {
        _logger.e('Error getting FCM token (attempt ${i + 1}): $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }
    }
    return null;
  }

  /// Listen for token refresh and update backend
  static void setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      _logger.i('FCM token refreshed: ${newToken.substring(0, 20)}...');
      try {
        await _authRepository.updateFCMToken(newToken);
        _logger.i('Refreshed FCM token uploaded successfully');
      } catch (e) {
        _logger.e('Failed to upload refreshed FCM token: $e');
      }
    });
  }

  /// Delete FCM token (call on logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _logger.i('FCM token deleted');
    } catch (e) {
      _logger.e('Failed to delete FCM token: $e');
    }
  }
}
