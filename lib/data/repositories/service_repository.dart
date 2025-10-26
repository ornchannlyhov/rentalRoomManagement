import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:receipts_v2/core/helpers/api_helper.dart';
import 'package:receipts_v2/core/helpers/sync_operation_helper.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/dtos/service_dto.dart';

// Top-level functions for compute() isolation
List<Service> _parseServices(String jsonString) {
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData.map((json) => ServiceDto.fromJson(json).toService()).toList();
}

String _encodeServices(List<Service> services) {
  return jsonEncode(services
      .map((s) => ServiceDto(
            id: s.id,
            name: s.name,
            price: s.price,
            buildingId: s.buildingId,
          ).toJson())
      .toList());
}

List<Map<String, dynamic>> _parsePendingChanges(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

class ServiceRepository {
  final String storageKey = 'service_secure_data';
  final String pendingChangesKey = 'service_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Service> _serviceCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  ServiceRepository();

  Future<void> load() async {
    try {
      // Load services with compute() for better performance
      final jsonString = await _apiHelper.storage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _serviceCache = await compute(_parseServices, jsonString);
      } else {
        _serviceCache = [];
      }

      // Load pending changes with compute()
      final pendingString =
          await _apiHelper.storage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges = await compute(_parsePendingChanges, pendingString);
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      throw Exception('Failed to load service data: $e');
    }
  }

  Future<void> save() async {
    try {
      // Only save if there's actual data
      if (_serviceCache.isNotEmpty) {
        final jsonString = await compute(_encodeServices, _serviceCache);
        await _apiHelper.storage.write(key: storageKey, value: jsonString);
      }

      // Save pending changes
      if (_pendingChanges.isNotEmpty) {
        final pendingJson = jsonEncode(_pendingChanges);
        await _apiHelper.storage.write(
          key: pendingChangesKey,
          value: pendingJson,
        );
      }
    } catch (e) {
      throw Exception('Failed to save service data: $e');
    }
  }

  Future<void> clear() async {
    await _apiHelper.storage.delete(key: storageKey);
    await _apiHelper.storage.delete(key: pendingChangesKey);
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

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final success = await _syncHelper.applyPendingChange(change);
      if (success) {
        successfulChanges.add(i);
      }
    }

    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
      await _apiHelper.storage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint,
  ) async {
    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
    });
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
      addPendingChange: (type, data) => _addPendingChange(
        type,
        {...data, 'localId': newService.id},
        '/services',
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
      addPendingChange: (type, data) => _addPendingChange(
        type,
        data,
        '/services/${updatedService.id}',
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
      addPendingChange: (type, data) => _addPendingChange(
        type,
        data,
        '/services/$serviceId',
      ),
    );

    await save();
  }

  Future<void> restoreService(int restoreIndex, Service service) async {
    _serviceCache.insert(restoreIndex, service);
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
}
