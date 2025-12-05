import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class HealthCheckService {
  static final Logger _logger = Logger();
  static final String _baseUrl = dotenv.env['API_URL'] ?? '';

  /// Check if backend is healthy and responsive
  /// Returns true if backend is up and running
  /// Returns false if backend is down, slow, or unreachable
  static Future<bool> checkBackendHealth() async {
    try {
      _logger.i('Checking backend health...');

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await dio.get('$_baseUrl/health');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          _logger.i('Backend is healthy: ${data['message']}');
          return true;
        }
      }

      _logger.w('Backend health check failed: Invalid response');
      return false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _logger.e('Backend health check timeout (>15s)');
      } else if (e.type == DioExceptionType.connectionError) {
        _logger.e('Cannot connect to backend');
      } else {
        _logger.e('Backend health check error: ${e.message}');
      }
      return false;
    } catch (e) {
      _logger.e('Unexpected error during health check: $e');
      return false;
    }
  }
}
