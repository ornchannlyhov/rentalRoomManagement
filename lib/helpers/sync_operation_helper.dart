import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/helpers/api_helper.dart';

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
/// Automatically handles:
/// - Network availability checks
/// - Token authentication
/// - Pending changes queue
/// - Local cache updates
class SyncOperationHelper {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiHelper _apiHelper = ApiHelper.instance;

  /// Execute a CREATE operation with offline support
  /// 
  /// [endpoint] - API endpoint (e.g., '/buildings')
  /// [data] - Request body data
  /// [fromJson] - Function to convert response JSON to model
  /// [addToCache] - Function to add item to local cache
  /// [addPendingChange] - Function to queue change for later sync
  Future<SyncResult<T>> create<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    required Future<void> Function(T) addToCache,
    required Future<void> Function(String type, Map<String, dynamic> data) addPendingChange,
    T? offlineModel,
  }) async {
    if (await _apiHelper.hasNetwork()) {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        try {
          final response = await _apiHelper.dio.post(
            '${_apiHelper.baseUrl}$endpoint',
            data: data,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] == true) {
            throw Exception('Request cancelled');
          }

          if (response.statusCode == 201) {
            final createdItem = fromJson(response.data['data']);
            await addToCache(createdItem);
            return SyncResult(success: true, data: createdItem, wasOnline: true);
          }
        } catch (e) {
          // Fall through to offline handling
        }
      }
    }

    // Offline creation
    if (offlineModel != null) {
      await addToCache(offlineModel);
    }
    
    await addPendingChange('create', data);
    return SyncResult(success: true, data: offlineModel, wasOnline: false);
  }

  /// Execute an UPDATE operation with offline support
  /// 
  /// [endpoint] - API endpoint (e.g., '/buildings/123')
  /// [data] - Request body data
  /// [updateCache] - Function to update item in local cache
  /// [addPendingChange] - Function to queue change for later sync
  Future<SyncResult<void>> update({
    required String endpoint,
    required Map<String, dynamic> data,
    required Future<void> Function() updateCache,
    required Future<void> Function(String type, Map<String, dynamic> data) addPendingChange,
  }) async {
    bool syncedOnline = false;

    if (await _apiHelper.hasNetwork()) {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        try {
          final response = await _apiHelper.dio.put(
            '${_apiHelper.baseUrl}$endpoint',
            data: data,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true && response.statusCode == 200) {
            syncedOnline = true;
          }
        } catch (e) {
          // Fall through to offline handling
        }
      }
    }

    // Update local cache
    await updateCache();

    // Add to pending changes if not synced online
    if (!syncedOnline) {
      await addPendingChange('update', data);
    }

    return SyncResult(success: true, wasOnline: syncedOnline);
  }

  /// Execute a DELETE operation with offline support
  /// 
  /// [endpoint] - API endpoint (e.g., '/buildings/123')
  /// [id] - ID of the item to delete
  /// [deleteFromCache] - Function to delete item from local cache
  /// [addPendingChange] - Function to queue change for later sync
  Future<SyncResult<void>> delete({
    required String endpoint,
    required String id,
    required Future<void> Function() deleteFromCache,
    required Future<void> Function(String type, Map<String, dynamic> data) addPendingChange,
  }) async {
    bool syncedOnline = false;

    if (await _apiHelper.hasNetwork()) {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        try {
          final response = await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}$endpoint',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true && response.statusCode == 200) {
            syncedOnline = true;
          }
        } catch (e) {
          // Fall through to offline handling
        }
      }
    }

    // Delete from local cache
    await deleteFromCache();

    // Add to pending changes if not synced online
    if (!syncedOnline) {
      await addPendingChange('delete', {'id': id});
    }

    return SyncResult(success: true, wasOnline: syncedOnline);
  }

  /// Fetch data from API
  /// 
  /// [endpoint] - API endpoint (e.g., '/buildings')
  /// [fromJsonList] - Function to convert response JSON array to model list
  Future<SyncResult<List<T>>> fetch<T>({
    required String endpoint,
    required List<T> Function(List<dynamic>) fromJsonList,
  }) async {
    if (!await _apiHelper.hasNetwork()) {
      return SyncResult(success: false, wasOnline: false);
    }

    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) {
      return SyncResult(success: false, wasOnline: false);
    }

    try {
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}$endpoint',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

  /// Apply a pending change to the API
  /// 
  /// [change] - Pending change object with type and data
  Future<bool> applyPendingChange(Map<String, dynamic> change) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) return false;

    final type = change['type'];
    final data = change['data'];
    final endpoint = change['endpoint'];

    if (endpoint == null) return false;

    try {
      switch (type) {
        case 'create':
          await _apiHelper.dio.post(
            '${_apiHelper.baseUrl}$endpoint',
            data: data,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          break;
        case 'update':
          await _apiHelper.dio.put(
            '${_apiHelper.baseUrl}$endpoint',
            data: data,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          break;
        case 'delete':
          await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}$endpoint',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          break;
        default:
          return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}