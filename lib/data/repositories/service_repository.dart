import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/dtos/service_dto.dart';
import 'package:logger/logger.dart';

class ServiceRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'service_secure_data';
  final String pendingChangesKey = 'service_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Service> _serviceCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  Future<void> load() async {
    try {
      _logger.i('Loading services from secure storage');

      // Load services
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _serviceCache = jsonData
            .map((json) => ServiceDto.fromJson(json).toService())
            .toList();
        _logger.i('Loaded ${_serviceCache.length} services from storage');
      } else {
        _serviceCache = [];
      }

      // Load pending changes
      final pendingString = await _secureStorage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges =
            List<Map<String, dynamic>>.from(jsonDecode(pendingString));
        _logger.i('Loaded ${_pendingChanges.length} pending service changes');
      } else {
        _pendingChanges = [];
      }
    } catch (e) {
      _logger.e('Failed to load services from secure storage: $e');
      throw Exception('Failed to load service data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(_serviceCache
          .map((s) => ServiceDto(
                id: s.id,
                name: s.name,
                price: s.price,
                buildingId: s.buildingId,
              ).toJson())
          .toList());
      await _secureStorage.write(key: storageKey, value: jsonString);

      // Save pending changes
      if (_pendingChanges.isNotEmpty) {
        await _secureStorage.write(
          key: pendingChangesKey,
          value: jsonEncode(_pendingChanges),
        );
      }

      _logger.d(
          'Saved ${_serviceCache.length} services and ${_pendingChanges.length} pending changes to storage');
    } catch (e) {
      _logger.e('Failed to save services to secure storage: $e');
      throw Exception('Failed to save service data to secure storage: $e');
    }
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: storageKey);
    await _secureStorage.delete(key: pendingChangesKey);
    _serviceCache.clear();
    _pendingChanges.clear();
    _logger.i('Cleared service data from secure storage');
  }

  Future<void> _addPendingChange(String type, Map<String, dynamic> data) async {
    _pendingChanges.add({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await save();
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    _logger.i('Syncing ${_pendingChanges.length} pending service changes...');
    final successfulChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      try {
        await _applyPendingChange(change);
        successfulChanges.add(i);
      } catch (e) {
        _logger.e('Failed to apply pending service change: $e');
      }
    }

    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
      await _secureStorage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
      _logger.i(
          'Successfully synced ${successfulChanges.length} pending service changes');
    }
  }

  Future<void> _applyPendingChange(Map<String, dynamic> change) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) throw Exception('No auth token');

    final type = change['type'];
    final data = change['data'];

    switch (type) {
      case 'create':
        await _apiHelper.dio.post(
          '${_apiHelper.baseUrl}/services',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'update':
        await _apiHelper.dio.put(
          '${_apiHelper.baseUrl}/services/${data['id']}',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'delete':
        await _apiHelper.dio.delete(
          '${_apiHelper.baseUrl}/services/${data['id']}',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
    }
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    try {
      if (!await _apiHelper.hasNetwork()) {
        _logger.w('No network connection, skipping sync');
        return;
      }

      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        _logger.w('No auth token found, skipping sync');
        return;
      }

      // Sync pending changes first
      await _syncPendingChanges();

      _logger.i('Syncing services from API');
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/services',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) {
        _logger.w('Request cancelled due to network loss');
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> servicesJson = response.data['data'];
        _serviceCache = servicesJson
            .map((json) => ServiceDto.fromJson(json).toService())
            .toList();

        if (!skipHydration) {
          await save();
        }
        _logger.i('Synced ${_serviceCache.length} services from API');
      }
    } catch (e) {
      _logger.e('Failed to sync services from API: $e');
    }
  }

  Future<void> createService(Service newService) async {
    try {
      if (newService.buildingId.isEmpty) {
        throw Exception('Service must have a valid buildingId');
      }

      Service createdService = newService;
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Creating service via API: ${newService.name}');

          try {
            final response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}/services',
              data: {
                'buildingId': newService.buildingId,
                'name': newService.name,
                'price': newService.price,
              },
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 201) {
              final serviceDto = ServiceDto.fromJson(response.data['data']);
              createdService = serviceDto.toService();

              if (createdService.buildingId != newService.buildingId) {
                createdService = Service(
                  id: createdService.id,
                  name: createdService.name,
                  price: createdService.price,
                  buildingId: newService.buildingId,
                );
              }

              syncedOnline = true;
              _logger.i('Service created successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to create service online, will sync later: $e');
          }
        }
      }

      _serviceCache.add(createdService);

      if (!syncedOnline) {
        await _addPendingChange('create', {
          'buildingId': newService.buildingId,
          'name': newService.name,
          'price': newService.price,
          'localId': newService.id,
        });
      }

      await save();
    } catch (e) {
      _logger.e('Failed to create service: $e');
      throw Exception('Failed to create service: $e');
    }
  }

  Future<void> updateService(Service updatedService) async {
    try {
      if (updatedService.buildingId.isEmpty) {
        throw Exception('Service must have a valid buildingId');
      }

      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating service via API: ${updatedService.id}');

          try {
            final response = await _apiHelper.dio.put(
              '${_apiHelper.baseUrl}/services/${updatedService.id}',
              data: {
                'name': updatedService.name,
                'price': updatedService.price,
                'buildingId': updatedService.buildingId,
              },
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Service updated successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to update service online, will sync later: $e');
          }
        }
      }

      final index = _serviceCache.indexWhere((s) => s.id == updatedService.id);
      if (index != -1) {
        _serviceCache[index] = updatedService;

        if (!syncedOnline) {
          await _addPendingChange('update', {
            'id': updatedService.id,
            'name': updatedService.name,
            'price': updatedService.price,
            'buildingId': updatedService.buildingId,
          });
        }

        await save();
        _logger.i('Service updated in local cache');
      } else {
        throw Exception('Service not found: ${updatedService.id}');
      }
    } catch (e) {
      _logger.e('Failed to update service: $e');
      throw Exception('Failed to update service: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting service via API: $serviceId');

          try {
            final response = await _apiHelper.dio.delete(
              '${_apiHelper.baseUrl}/services/$serviceId',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Service deleted successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to delete service online, will sync later: $e');
          }
        }
      }

      _serviceCache.removeWhere((s) => s.id == serviceId);

      if (!syncedOnline) {
        await _addPendingChange('delete', {'id': serviceId});
      }

      await save();
      _logger.i('Service deleted from local cache');
    } catch (e) {
      _logger.e('Failed to delete service: $e');
      throw Exception('Failed to delete service: $e');
    }
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

  bool hasPendingChanges() {
    return _pendingChanges.isNotEmpty;
  }

  int getPendingChangesCount() {
    return _pendingChanges.length;
  }
}
