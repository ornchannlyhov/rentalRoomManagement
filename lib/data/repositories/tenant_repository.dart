import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/core/api_helper.dart';
import 'package:receipts_v2/data/dtos/tenant_dto.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';

class TenantRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();
  final AuthRepository _authRepository;

  List<Tenant> _tenantCache = [];

  TenantRepository(this._authRepository);

  Future<bool> _hasNetwork() => _apiHelper.hasNetwork();

  Future<String?> _getToken() async {
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }
    return token;
  }

  Future<List<TenantDto>> _fetchTenantDtos(
      {String? roomId, String? search}) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/tenants';

    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (roomId != null) queryParams['roomId'] = roomId;
      if (search != null) queryParams['search'] = search;

      final response = await _apiHelper.dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((json) => TenantDto.fromJson(json)).toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to fetch tenants: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      _logger.e('fetchTenantDtos error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to fetch tenants';
      throw Exception(errorMessage);
    }
  }

  Future<void> load({String? roomId, String? search}) async {
    try {
      final dtos = await _fetchTenantDtos(roomId: roomId, search: search);
      _tenantCache = dtos.map((dto) => dto.toTenant()).toList();
      _logger.i('Tenants loaded successfully: ${_tenantCache.length} tenants');
    } catch (e) {
      _logger.e('Failed to load tenants: $e');
      if (_tenantCache.isEmpty) {
        throw Exception('Failed to load tenant data: $e');
      }
      rethrow;
    }
  }

  Future<Tenant> createTenant(Tenant newTenant) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/tenants';

    try {
      final tenantDto = TenantDto(
        id: newTenant.id,
        name: newTenant.name,
        phoneNumber: newTenant.phoneNumber,
        gender: newTenant.gender.toString().split('.').last,
        roomId: newTenant.room?.id,
      );

      final response = await _apiHelper.dio.post(
        url,
        data: tenantDto.toRequestJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdDto =
            TenantDto.fromJson(response.data['data'] ?? response.data);
        final createdTenant = createdDto.toTenant();
        _tenantCache.add(createdTenant);
        _logger.i('Tenant created successfully');
        return createdTenant;
      } else {
        throw Exception('Failed to create tenant: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      _logger.e('createTenant error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to create tenant';
      throw Exception(errorMessage);
    }
  }

  Future<Tenant> updateTenant(Tenant updatedTenant) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/tenants/${updatedTenant.id}';

    try {
      final tenantDto = TenantDto(
        id: updatedTenant.id,
        name: updatedTenant.name,
        phoneNumber: updatedTenant.phoneNumber,
        gender: updatedTenant.gender.toString().split('.').last,
        roomId: updatedTenant.room?.id,
      );

      final response = await _apiHelper.dio.put(
        url,
        data: tenantDto.toRequestJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final index = _tenantCache.indexWhere((t) => t.id == updatedTenant.id);
        if (index != -1) {
          _tenantCache[index] = updatedTenant;
        }
        _logger.i('Tenant updated successfully');
        return updatedTenant;
      } else {
        throw Exception('Failed to update tenant: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Tenant not found or not authorized');
      }
      _logger.e('updateTenant error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to update tenant';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/tenants/$tenantId';

    try {
      final response = await _apiHelper.dio.delete(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _tenantCache.removeWhere((t) => t.id == tenantId);
        _logger.i('Tenant deleted successfully');
      } else {
        throw Exception('Failed to delete tenant: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Tenant not found or not authorized');
      }
      _logger.e('deleteTenant error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to delete tenant';
      throw Exception(errorMessage);
    }
  }

  Future<void> removeRoom(String tenantId) async {
    final tenant = _tenantCache.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => throw Exception('Tenant not found: $tenantId'),
    );

    final updatedTenant = tenant.copyWith(room: null);
    await updateTenant(updatedTenant);
  }

  List<Tenant> getAllTenant() {
    return List.unmodifiable(_tenantCache);
  }

  List<Tenant> getTenantsByBuilding(String buildingId) {
    return _tenantCache.where((tenant) {
      return tenant.room != null && tenant.room!.building?.id == buildingId;
    }).toList();
  }

  List<Tenant> getTenantsByRoom(String roomId) {
    return _tenantCache.where((tenant) {
      return tenant.room?.id == roomId;
    }).toList();
  }

  Tenant? getTenantById(String tenantId) {
    try {
      return _tenantCache.firstWhere((t) => t.id == tenantId);
    } catch (e) {
      return null;
    }
  }

  List<Tenant> searchTenants(String query) {
    final lowerQuery = query.toLowerCase();
    return _tenantCache.where((tenant) {
      return tenant.name.toLowerCase().contains(lowerQuery) ||
          tenant.phoneNumber.contains(query);
    }).toList();
  }

  void clearCache() {
    _tenantCache.clear();
    _logger.i('Tenant cache cleared');
  }

  bool hasData() {
    return _tenantCache.isNotEmpty;
  }
}
