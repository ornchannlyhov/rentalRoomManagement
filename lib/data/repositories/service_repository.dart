import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/core/api_helper.dart';
import 'package:receipts_v2/data/dtos/service_dto.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';

class ServiceRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();
  final AuthRepository _authRepository;

  List<Service> _serviceCache = [];

  ServiceRepository(this._authRepository);

  Future<bool> _hasNetwork() => _apiHelper.hasNetwork();

  Future<String?> _getToken() async {
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }
    return token;
  }

  Future<List<ServiceDto>> _fetchServiceDtos() async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/services';

    try {
      final response = await _apiHelper.dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((json) => ServiceDto.fromJson(json)).toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to fetch services: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      _logger.e('fetchServiceDtos error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to fetch services';
      throw Exception(errorMessage);
    }
  }

  Future<void> load() async {
    try {
      final dtos = await _fetchServiceDtos();
      _serviceCache = dtos.map((dto) => dto.toService()).toList();
      _logger
          .i('Services loaded successfully: ${_serviceCache.length} services');
    } catch (e) {
      _logger.e('Failed to load services: $e');
      if (_serviceCache.isEmpty) {
        throw Exception('Failed to load service data: $e');
      }
      rethrow;
    }
  }

  Future<Service> createService(Service newService) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/services';

    try {
      final requestBody = {
        'buildingId': newService.buildingId,
        'name': newService.name,
        'price': newService.price,
      };

      final response = await _apiHelper.dio.post(
        url,
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final serviceDto =
            ServiceDto.fromJson(response.data['data'] ?? response.data);
        final createdService = serviceDto.toService();
        _serviceCache.add(createdService);
        _logger.i('Service created successfully');
        return createdService;
      } else {
        throw Exception('Failed to create service: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Building not found or not authorized');
      }
      _logger.e('createService error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to create service';
      throw Exception(errorMessage);
    }
  }

  Future<Service> updateService(Service updatedService) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/services/${updatedService.id}';

    try {
      final requestBody = {
        'name': updatedService.name,
        'price': updatedService.price,
      };

      final response = await _apiHelper.dio.put(
        url,
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final index =
            _serviceCache.indexWhere((s) => s.id == updatedService.id);
        if (index != -1) {
          _serviceCache[index] = updatedService;
        }
        _logger.i('Service updated successfully');
        return updatedService;
      } else if (response.statusCode == 400) {
        throw Exception('No changes detected');
      } else {
        throw Exception('Failed to update service: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Service not found or not authorized');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('No changes detected');
      }
      _logger.e('updateService error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to update service';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteService(String serviceId) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/services/$serviceId';

    try {
      final response = await _apiHelper.dio.delete(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _serviceCache.removeWhere((s) => s.id == serviceId);
        _logger.i('Service deleted successfully');
      } else {
        throw Exception('Failed to delete service: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Service not found or not authorized');
      }
      _logger.e('deleteService error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to delete service';
      throw Exception(errorMessage);
    }
  }

  List<Service> getAllServices() {
    return List.unmodifiable(_serviceCache);
  }

  List<Service> getServicesByBuilding(String buildingId) {
    return _serviceCache
        .where((service) => service.buildingId == buildingId)
        .toList();
  }

  Service? getServiceById(String serviceId) {
    try {
      return _serviceCache.firstWhere((s) => s.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _serviceCache.clear();
    _logger.i('Service cache cleared');
  }

  bool hasData() {
    return _serviceCache.isNotEmpty;
  }
}
