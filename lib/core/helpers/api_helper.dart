import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart'; 

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

  /// Check for internet access (Web-compatible)
  Future<bool> hasNetwork() async {
    if (kIsWeb) {
      return true;
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // ignore: unrelated_type_equality_checks
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
