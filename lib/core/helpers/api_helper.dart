import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart'; 

class ApiHelper {
  final CancelToken _cancelToken = CancelToken();

  /// Public getter for cancel token
  CancelToken get cancelToken => _cancelToken;

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
          // Pass network errors on to the caller so it can queue the change.
          // Only our own backend counts: a failing third-party call (exchange
          // rates) must not mark the app offline.
          if (_isNetworkError(e) &&
              e.requestOptions.uri.toString().startsWith(baseUrl)) {
            _noNetworkController.add(null);
            _recordProbe(false);
          }

          if (e.response?.statusCode == 401) {
            _unauthenticatedController.add(null);
          }

          return handler.next(e);
        },
      ),
    );

    Connectivity().onConnectivityChanged.listen((_) async {
      // The connection changed, so the last probe result no longer holds.
      _lastProbeAt = null;
      await hasNetwork();
    });
  }

  static bool _isNetworkError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  /// Upload file with multipart/form-data
  Future<Response?> uploadWithFile({
    required String endpoint,
    required Map<String, dynamic> data,
    File? file,
    String? fileFieldName,
    String method = 'POST', // 'POST' or 'PUT'
  }) async {
    try {
      // Get auth token
      final token = await storage.read(key: 'auth_token');

      // Create FormData
      final formData = FormData();

      // Add all text fields
      data.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add file if provided
      if (file != null && fileFieldName != null) {
        String fileName = file.path.split('/').last;

        // Determine content type based on file extension
        String? mimeType;
        if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (fileName.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (fileName.endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        formData.files.add(
          MapEntry(
            fileFieldName,
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
              contentType: mimeType != null ? MediaType.parse(mimeType) : null,
            ),
          ),
        );
      }

      // Make request
      final response = await dio.request(
        '$baseUrl$endpoint',
        data: formData,
        options: Options(
          method: method,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            // Don't set Content-Type header - Dio will set it automatically with boundary
          },
          contentType: Headers.multipartFormDataContentType,
        ),
        cancelToken: _cancelToken,
      );

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Upload error: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected upload error: $e');
      }
      rethrow;
    }
  }

  /// Upload multiple files with multipart/form-data
  Future<Response?> uploadWithFiles({
    required String endpoint,
    required Map<String, dynamic> data,
    List<File>? files,
    String? fileFieldName,
    String method = 'POST',
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      final formData = FormData();

      // Add text fields
      data.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add multiple files
      if (files != null && files.isNotEmpty && fileFieldName != null) {
        for (var file in files) {
          String fileName = file.path.split('/').last;

          String? mimeType;
          if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
            mimeType = 'image/jpeg';
          } else if (fileName.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (fileName.endsWith('.gif')) {
            mimeType = 'image/gif';
          } else if (fileName.endsWith('.webp')) {
            mimeType = 'image/webp';
          }

          formData.files.add(
            MapEntry(
              fileFieldName,
              await MultipartFile.fromFile(
                file.path,
                filename: fileName,
                contentType:
                    mimeType != null ? MediaType.parse(mimeType) : null,
              ),
            ),
          );
        }
      }

      final response = await dio.request(
        '$baseUrl$endpoint',
        data: formData,
        options: Options(
          method: method,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          contentType: Headers.multipartFormDataContentType,
        ),
        cancelToken: _cancelToken,
      );

      return response;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Upload error: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected upload error: $e');
      }
      rethrow;
    }
  }

  // Online means our backend answered, not just that the phone has a
  // connection. The probe result is cached briefly because every create,
  // update, delete and sync asks.
  static const Duration _probeTtl = Duration(seconds: 10);
  final Dio _probeDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (_) => true,
    ),
  );
  bool _isOnline = true;
  bool? _lastProbeResult;
  DateTime? _lastProbeAt;
  Future<bool>? _probeInFlight;

  /// Whether the backend can be reached right now (Web-compatible).
  Future<bool> hasNetwork() async {
    if (kIsWeb) {
      return true;
    }

    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none)) {
        _recordProbe(false);
        return false;
      }
    } catch (_) {
      // Fall through to the backend probe.
    }

    final lastAt = _lastProbeAt;
    if (lastAt != null &&
        _lastProbeResult != null &&
        DateTime.now().difference(lastAt) < _probeTtl) {
      return _lastProbeResult!;
    }

    return _probeInFlight ??=
        _probeBackend().whenComplete(() => _probeInFlight = null);
  }

  Future<bool> _probeBackend() async {
    bool reachable;
    try {
      final response = await _probeDio.get('$baseUrl/health');
      reachable = (response.statusCode ?? 500) < 500;
    } catch (_) {
      reachable = false;
    }
    _recordProbe(reachable);
    return reachable;
  }

  /// Stores the latest reachability result and tells listeners when it
  /// changes, so the app can sync as soon as the backend is back.
  void _recordProbe(bool reachable) {
    _lastProbeResult = reachable;
    _lastProbeAt = DateTime.now();
    if (reachable != _isOnline) {
      _isOnline = reachable;
      _networkStatusController.add(reachable);
    }
  }

  void dispose() {
    _unauthenticatedController.close();
    _noNetworkController.close();
    _networkStatusController.close();
  }
}
