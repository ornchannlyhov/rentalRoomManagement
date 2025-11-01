import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiHelper {
  CancelToken _cancelToken = CancelToken();

  /// Public getter for cancel token
  CancelToken get cancelToken => _cancelToken;

  void cancelRequests() {
    _cancelToken.cancel('Network connection lost');
    _cancelToken = CancelToken();
  }

  // Singleton instance
  static final ApiHelper _instance = ApiHelper._privateConstructor();
  static ApiHelper get instance => _instance;

  final String baseUrl = dotenv.env['API_URL'] ?? '';
  final String apiKey = dotenv.env['API_KEY'] ?? '';

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final Dio dio = Dio(
    BaseOptions(
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final _unauthenticatedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthenticated => _unauthenticatedController.stream;

  final _noNetworkController = StreamController<void>.broadcast();
  Stream<void> get onNoNetwork => _noNetworkController.stream;

  final _networkStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onNetworkStatusChanged => _networkStatusController.stream;

  ApiHelper._privateConstructor() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            cancelRequests();
            _noNetworkController.add(null);
            _networkStatusController.add(false);
            return handler.resolve(
              Response(
                requestOptions: e.requestOptions,
                data: {'cancelled': true},
              ),
            );
          }

          if (e.response?.statusCode == 401) {
            _unauthenticatedController.add(null);
          }

          return handler.next(e);
        },
      ),
    );

    Connectivity().onConnectivityChanged.listen((result) async {
      final hasNet = await hasNetwork();
      _networkStatusController.add(hasNet);
    });
  }

  /// Check for internet access (Web-compatible)
  Future<bool> hasNetwork() async {
    // On web, if the page loaded, we have internet - just return true
    if (kIsWeb) {
      return true;
    }

    // On mobile/desktop, do proper connectivity check
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _unauthenticatedController.close();
    _noNetworkController.close();
    _networkStatusController.close();
  }
}
