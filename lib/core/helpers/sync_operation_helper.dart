import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';

/// Result of a sync operation
class SyncResult<T> {
  final bool success;
  final T? data;
  final bool wasOnline;

  SyncResult({
    required this.success,
    this.data,
    required this.wasOnline,
  });
}

/// Helper class for handling offline/online CRUD operations
class SyncOperationHelper {
  final ApiHelper _apiHelper = ApiHelper.instance;

  /// Execute a CREATE operation with offline support (with optional file)
  Future<SyncResult<T>> create<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    required Future<void> Function(T) addToCache,
    required Future<void> Function(
      String type,
      String endpoint,
      Map<String, dynamic> data,
    ) addPendingChange,
    T? offlineModel,
    File? file, 
    String? fileFieldName, 
  }) async {
    if (await _apiHelper.hasNetwork()) {
      final token = await _apiHelper.storage.read(key: 'auth_token');
      if (token != null) {
        try {
          Response? response;

          if (file != null && fileFieldName != null) {
            response = await _apiHelper.uploadWithFile(
              endpoint: endpoint,
              data: data,
              file: file,
              fileFieldName: fileFieldName,
              method: 'POST',
            );
          } else {
            // Regular JSON POST
            response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}$endpoint',
              data: data,
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
              cancelToken: _apiHelper.cancelToken,
            );
          }

          if (response?.data['cancelled'] == true) {
            throw Exception('Request cancelled');
          }

          if (response?.statusCode == 201 || response?.statusCode == 200) {
            final createdItem = fromJson(response!.data['data']);
            await addToCache(createdItem);
            return SyncResult(
                success: true, data: createdItem, wasOnline: true);
          }

          // Non-201/200 response - treat as failure
          throw Exception('Unexpected status code: ${response?.statusCode}');
        } on DioException catch (e) {
          // Only queue if it's a definite network failure
          // Don't queue on 4xx/5xx errors (server processed it)
          if (e.type != DioExceptionType.badResponse) {
            // Network timeout/connection error - queue for retry
            if (offlineModel != null) {
              await addToCache(offlineModel);
            }
            await addPendingChange('create', endpoint, data);
            return SyncResult(
                success: true, data: offlineModel, wasOnline: false);
          }

          // Server error - don't queue, propagate error
          rethrow;
        } catch (e) {
          // Other errors - don't queue automatically
          rethrow;
        }
      }
    }

    // Offline creation (no network available)
    if (offlineModel != null) {
      await addToCache(offlineModel);
    }
    await addPendingChange('create', endpoint, data);
    return SyncResult(success: true, data: offlineModel, wasOnline: false);
  }

  /// Execute an UPDATE operation with offline support (with optional file)
  Future<SyncResult<void>> update({
    required String endpoint,
    required Map<String, dynamic> data,
    required Future<void> Function() updateCache,
    required Future<void> Function(
      String type,
      String endpoint,
      Map<String, dynamic> data,
    ) addPendingChange,
    File? file, 
    String? fileFieldName, 
  }) async {
    bool syncedOnline = false;

    if (await _apiHelper.hasNetwork()) {
      final token = await _apiHelper.storage.read(key: 'auth_token');
      if (token != null) {
        try {
          Response? response;

          if (file != null && fileFieldName != null) {
            response = await _apiHelper.uploadWithFile(
              endpoint: endpoint,
              data: data,
              file: file,
              fileFieldName: fileFieldName,
              method: 'PUT',
            );
          } else {
            // Regular JSON PUT
            response = await _apiHelper.dio.put(
              '${_apiHelper.baseUrl}$endpoint',
              data: data,
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
              cancelToken: _apiHelper.cancelToken,
            );
          }

          if (response?.data['cancelled'] != true &&
              response?.statusCode == 200) {
            syncedOnline = true;
          } else if (response?.statusCode != 200) {
            throw Exception('Unexpected status code: ${response?.statusCode}');
          }
        } on DioException catch (e) {
          // Only queue on network failures, not server errors
          if (e.type == DioExceptionType.badResponse) {
            rethrow;
          }
          // Network error - will queue below
        } catch (e) {
          rethrow;
        }
      }
    }

    // Update local cache regardless
    await updateCache();

    // Add to pending changes if not synced online
    if (!syncedOnline) {
      await addPendingChange('update', endpoint, data);
    }

    return SyncResult(success: true, wasOnline: syncedOnline);
  }

  /// Execute a DELETE operation with offline support
  Future<SyncResult<void>> delete({
    required String endpoint,
    required String id,
    required Future<void> Function() deleteFromCache,
    required Future<void> Function(
      String type,
      String endpoint,
      Map<String, dynamic> data,
    ) addPendingChange,
  }) async {
    bool syncedOnline = false;

    if (await _apiHelper.hasNetwork()) {
      final token = await _apiHelper.storage.read(key: 'auth_token');
      if (token != null) {
        try {
          final response = await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}$endpoint',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode == 200) {
            syncedOnline = true;
          } else if (response.statusCode != 200) {
            throw Exception('Unexpected status code: ${response.statusCode}');
          }
        } on DioException catch (e) {
          // Only queue on network failures, not server errors
          if (e.type == DioExceptionType.badResponse) {
            rethrow;
          }
          // Network error - will queue below
        } catch (e) {
          rethrow;
        }
      }
    }

    // Delete from local cache regardless
    await deleteFromCache();

    // Add to pending changes if not synced online
    if (!syncedOnline) {
      await addPendingChange('delete', endpoint, {'id': id});
    }

    return SyncResult(success: true, wasOnline: syncedOnline);
  }

  /// Fetch data from API
  Future<SyncResult<List<T>>> fetch<T>({
    required String endpoint,
    required List<T> Function(List<dynamic>) fromJsonList,
  }) async {
    if (!await _apiHelper.hasNetwork()) {
      return SyncResult(success: false, wasOnline: false);
    }

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) {
      return SyncResult(success: false, wasOnline: false);
    }

    try {
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}$endpoint',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) {
        return SyncResult(success: false, wasOnline: true);
      }

      if (response.statusCode == 200) {
        final data = fromJsonList(response.data['data']);
        return SyncResult(success: true, data: data, wasOnline: true);
      }
    } catch (e) {
      return SyncResult(success: false, wasOnline: true);
    }

    return SyncResult(success: false, wasOnline: true);
  }

  /// Apply a pending change to the API (with file support)
  Future<bool> applyPendingChange(Map<String, dynamic> change) async {
    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) return false;

    final type = change['type'];
    final data = change['data'] as Map<String, dynamic>;
    final endpoint = change['endpoint'];
    final filePath = change['filePath'] as String?; 
    final fileFieldName =
        change['fileFieldName'] as String?;

    if (endpoint == null) return false;

    File? file;
    if (filePath != null && fileFieldName != null) {
      final fileExists = await File(filePath).exists();
      if (fileExists) {
        file = File(filePath);
      } else {
        if (kDebugMode) {
          print('Warning: File not found at $filePath, syncing without file');
        }
      }
    }

    try {
      Response? response;

      switch (type) {
        case 'create':
          if (file != null && fileFieldName != null) {
            response = await _apiHelper.uploadWithFile(
              endpoint: endpoint,
              data: data,
              file: file,
              fileFieldName: fileFieldName,
              method: 'POST',
            );
          } else {
            response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}$endpoint',
              data: data,
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                validateStatus: (status) => status! < 500,
              ),
            );
          }

          // 201 = success, 409 = already exists (treat as success)
          return response?.statusCode == 201 ||
              response?.statusCode == 200 ||
              response?.statusCode == 409;

        case 'update':
          if (file != null && fileFieldName != null) {
            response = await _apiHelper.uploadWithFile(
              endpoint: endpoint,
              data: data,
              file: file,
              fileFieldName: fileFieldName,
              method: 'PUT',
            );
          } else {
            response = await _apiHelper.dio.put(
              '${_apiHelper.baseUrl}$endpoint',
              data: data,
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                validateStatus: (status) => status! < 500,
              ),
            );
          }

          // 200 = success, 404 = already deleted (treat as success)
          return response?.statusCode == 200 || response?.statusCode == 404;

        case 'delete':
          response = await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}$endpoint',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              validateStatus: (status) => status! < 500,
            ),
          );

          // 200 = success, 404 = already deleted (treat as success)
          return response.statusCode == 200 || response.statusCode == 404;

        default:
          return false;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error applying pending change: ${e.message}');
      }
      // Only fail on network errors, not 4xx/5xx
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return false;
      }

      // Server errors - consider the operation failed
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error applying pending change: $e');
      }
      return false;
    }
  }
}
