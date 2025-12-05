import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/data/dtos/service_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

class ServiceRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Service> _serviceCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  ServiceRepository(this._databaseService);

  Future<void> load() async {
    try {
      final servicesList = _databaseService.servicesBox.values.toList();
      _serviceCache = servicesList
          .map((e) =>
              ServiceDto.fromJson(Map<String, dynamic>.from(e)).toService())
          .toList();

      final pendingList = _databaseService.servicesPendingBox.values.toList();
      _pendingChanges =
          pendingList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw Exception('Failed to load service data: $e');
    }
  }

  Future<void> loadWithoutHydration() async {
    final servicesList = _databaseService.servicesBox.values.toList();
    _serviceCache = servicesList
        .map((e) =>
            ServiceDto.fromJson(Map<String, dynamic>.from(e)).toService())
        .toList();

    final pendingList = _databaseService.servicesPendingBox.values.toList();
    _pendingChanges =
        pendingList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> save() async {
    try {
      await _databaseService.servicesBox.clear();
      for (var i = 0; i < _serviceCache.length; i++) {
        final dto = ServiceDto(
          id: _serviceCache[i].id,
          name: _serviceCache[i].name,
          price: _serviceCache[i].price,
          buildingId: _serviceCache[i].buildingId,
        );
        await _databaseService.servicesBox.put(i, dto.toJson());
      }

      await _databaseService.servicesPendingBox.clear();
      for (var i = 0; i < _pendingChanges.length; i++) {
        await _databaseService.servicesPendingBox.put(i, _pendingChanges[i]);
      }
    } catch (e) {
      throw Exception('Failed to save service data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.servicesBox.clear();
    await _databaseService.servicesPendingBox.clear();
    _serviceCache.clear();
    _pendingChanges.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    await _syncPendingChanges();

    final result = await _syncHelper.fetch<Service>(
      endpoint: '/services',
      fromJsonList: (jsonList) => jsonList
          .map((json) => ServiceDto.fromJson(json).toService())
          .toList(),
    );

    if (result.success && result.data != null) {
      _serviceCache = result.data!;
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final successfulChanges = <int>[];
    final failedChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final retryCount = change['retryCount'] ?? 0;

      // Max 5 retries for failed changes
      if (retryCount >= 5) {
        failedChanges.add(i);
        if (kDebugMode) {
          print(
              'Service pending change exceeded retry limit: ${change['type']} ${change['endpoint']}');
        }
        continue;
      }

      final success = await _syncHelper.applyPendingChange(change);

      if (success) {
        successfulChanges.add(i);
        if (kDebugMode) {
          print(
              'Successfully synced service pending change: ${change['type']} ${change['endpoint']}');
        }
      } else {
        // Increment retry count
        _pendingChanges[i]['retryCount'] = retryCount + 1;
        if (kDebugMode) {
          print(
              'Failed to sync service pending change (retry ${retryCount + 1}/5): ${change['type']} ${change['endpoint']}');
        }
      }
    }

    // Remove successful and permanently failed changes (reverse order)
    final toRemove = [...successfulChanges, ...failedChanges]
      ..sort((a, b) => b.compareTo(a));
    for (final index in toRemove) {
      _pendingChanges.removeAt(index);
    }

    if (successfulChanges.isNotEmpty || failedChanges.isNotEmpty) {
      await save();
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint,
  ) async {
    // Check for duplicate pending changes
    final isDuplicate = _pendingChanges.any((change) {
      if (change['type'] != type || change['endpoint'] != endpoint) {
        return false;
      }

      // For creates with localId, check if localId matches
      if (type == 'create' && data['localId'] != null) {
        return change['data']['localId'] == data['localId'];
      }

      // For updates/deletes, check if id matches
      if (data['id'] != null) {
        return change['data']['id'] == data['id'];
      }

      // For services, also check by buildingId + name combination (services are unique per building + name)
      if (type == 'create' &&
          data['buildingId'] != null &&
          data['name'] != null) {
        return change['data']['buildingId'] == data['buildingId'] &&
            change['data']['name'] == data['name'];
      }

      // Fallback: compare full data
      return jsonEncode(change['data']) == jsonEncode(data);
    });

    if (isDuplicate) {
      if (kDebugMode) {
        print('Skipping duplicate service pending change: $type $endpoint');
      }
      return;
    }

    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });

    if (kDebugMode) {
      print('Added service pending change: $type $endpoint');
    }
  }

  Future<void> createService(Service newService) async {
    if (newService.buildingId.isEmpty) {
      throw Exception('Service must have a valid buildingId');
    }

    final requestData = {
      'buildingId': newService.buildingId,
      'name': newService.name,
      'price': newService.price,
    };

    await _syncHelper.create<Service>(
      endpoint: '/services',
      data: requestData,
      fromJson: (json) => ServiceDto.fromJson(json).toService(),
      addToCache: (service) async {
        _serviceCache.add(service);
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        {
          ...data,
          'localId': newService.id
        }, // Include localId for offline mapping
        endpoint,
      ),
      offlineModel: newService,
    );

    await save();
  }

  Future<void> updateService(Service updatedService) async {
    if (updatedService.buildingId.isEmpty) {
      throw Exception('Service must have a valid buildingId');
    }

    final requestData = {
      'name': updatedService.name,
      'price': updatedService.price,
      'buildingId': updatedService.buildingId,
    };

    await _syncHelper.update(
      endpoint: '/services/${updatedService.id}',
      data: requestData,
      updateCache: () async {
        final index =
            _serviceCache.indexWhere((s) => s.id == updatedService.id);
        if (index != -1) {
          _serviceCache[index] = updatedService;
        } else {
          throw Exception('Service not found: ${updatedService.id}');
        }
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        data,
        endpoint,
      ),
    );

    await save();
  }

  Future<void> deleteService(String serviceId) async {
    await _syncHelper.delete(
      endpoint: '/services/$serviceId',
      id: serviceId,
      deleteFromCache: () async {
        _serviceCache.removeWhere((s) => s.id == serviceId);
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        data,
        endpoint,
      ),
    );

    await save();
  }

  List<Service> getAllServices() {
    return List.unmodifiable(_serviceCache);
  }

  List<Service> getServicesByBuilding(String buildingId) {
    return _serviceCache.where((s) => s.buildingId == buildingId).toList();
  }

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;

  /// Get list of pending changes for debugging/display
  List<Map<String, dynamic>> getPendingChanges() {
    return List.unmodifiable(_pendingChanges);
  }
}
