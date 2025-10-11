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
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Service> _serviceCache = [];

  Future<void> load() async {
    try {
      _logger.i('Loading services from secure storage');
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
      _logger.d('Saved ${_serviceCache.length} services to storage');
    } catch (e) {
      _logger.e('Failed to save services to secure storage: $e');
      throw Exception('Failed to save service data to secure storage: $e');
    }
  }

// Update syncFromApi method
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
      // Validate required fields
      if (newService.buildingId.isEmpty) {
        throw Exception('Service must have a valid buildingId');
      }

      Service createdService =
          newService; // Default to input service for offline case

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Creating service via API: ${newService.name}');

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

          if (response.data['cancelled'] == true) {
            _logger.w('Request cancelled, saving locally');
            _serviceCache.add(newService);
            await save();
            return;
          }

          if (response.statusCode == 201) {
            final serviceDto = ServiceDto.fromJson(response.data['data']);
            createdService = serviceDto.toService();

            // Ensure buildingId is preserved
            if (createdService.buildingId != newService.buildingId) {
              _logger.w(
                  'API returned different buildingId for service ${createdService.id}. Overriding with original.');
              createdService = Service(
                id: createdService.id,
                name: createdService.name,
                price: createdService.price,
                buildingId: newService.buildingId,
              );
            }

            _serviceCache.add(createdService);
            _logger.i('Service created successfully via API');
          }
        } else {
          // No token, proceed with local creation
          _serviceCache.add(newService);
        }
      } else {
        // No network, proceed with local creation
        _serviceCache.add(newService);
      }

      await save();
    } catch (e) {
      _logger.e('Failed to create service: $e');
      throw Exception('Failed to create service: $e');
    }
  }

  Future<void> updateService(Service updatedService) async {
    try {
      // Validate buildingId
      if (updatedService.buildingId.isEmpty) {
        throw Exception('Service must have a valid buildingId');
      }

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating service via API: ${updatedService.id}');

          final response = await _apiHelper.dio.put(
            '${_apiHelper.baseUrl}/services/${updatedService.id}',
            data: {
              'name': updatedService.name,
              'price': updatedService.price,
              'buildingId': updatedService.buildingId, // Include buildingId
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode != 200) {
            throw Exception('Failed to update service via API');
          }
        }
      }

      final index = _serviceCache.indexWhere((s) => s.id == updatedService.id);
      if (index != -1) {
        // Preserve buildingId if API doesn't update it
        if (_serviceCache[index].buildingId != updatedService.buildingId) {
          _logger.w(
              'Updating service ${updatedService.id} with different buildingId. Original: ${_serviceCache[index].buildingId}, New: ${updatedService.buildingId}');
        }
        _serviceCache[index] = updatedService;
        await save();
        _logger.i('Service updated successfully');
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
      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting service via API: $serviceId');

          final response = await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}/services/$serviceId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode != 200) {
            throw Exception('Failed to delete service via API');
          }
        }
      }

      _serviceCache.removeWhere((s) => s.id == serviceId);
      await save();
      _logger.i('Service deleted successfully');
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
}
