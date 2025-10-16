import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/gender.dart';
import 'package:receipts_v2/data/dtos/tenant_dto.dart';
import 'package:receipts_v2/data/dtos/room_dto.dart';
import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:logger/logger.dart';

class TenantRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'tenant_secure_data';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Tenant> _tenantCache = [];

  Future<void> load() async {
    try {
      _logger.i('Loading tenants from secure storage');
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _tenantCache = jsonData.map((json) {
          final tenantDto = TenantDto.fromJson(json);
          final tenant = tenantDto.toTenant();

          // Preserve room and building references
          if (tenantDto.room != null) {
            tenant.room = tenantDto.room!.toRoom();
            if (tenantDto.room!.building != null) {
              tenant.room!.building = tenantDto.room!.building!.toBuilding();
            }
          }

          return tenant;
        }).toList();
        _logger.i('Loaded ${_tenantCache.length} tenants from storage');
      } else {
        _tenantCache = [];
      }
    } catch (e) {
      _logger.e('Failed to load tenants from secure storage: $e');
      throw Exception('Failed to load tenant data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(
        _tenantCache.map((tenant) {
          String genderStr;
          switch (tenant.gender) {
            case Gender.male:
              genderStr = 'male';
              break;
            case Gender.female:
              genderStr = 'female';
              break;
            default:
              genderStr = 'other';
          }

          return TenantDto(
            id: tenant.id,
            name: tenant.name,
            phoneNumber: tenant.phoneNumber,
            gender: genderStr,
            roomId: tenant.room?.id,
            room: tenant.room != null
                ? RoomDto(
                    id: tenant.room!.id,
                    roomNumber: tenant.room!.roomNumber,
                    roomStatus:
                        tenant.room!.roomStatus.toString().split('.').last,
                    price: tenant.room!.price,
                    buildingId: tenant.room!.building?.id,
                    building: tenant.room!.building != null
                        ? BuildingDto(
                            id: tenant.room!.building!.id,
                            name: tenant.room!.building!.name,
                            rentPrice: tenant.room!.building!.rentPrice,
                            electricPrice: tenant.room!.building!.electricPrice,
                            waterPrice: tenant.room!.building!.waterPrice,
                          )
                        : null,
                  )
                : null,
          ).toJson();
        }).toList(),
      );
      await _secureStorage.write(key: storageKey, value: jsonString);
      _logger.d('Saved ${_tenantCache.length} tenants to storage');
    } catch (e) {
      _logger.e('Failed to save tenants to secure storage: $e');
      throw Exception('Failed to save tenant data to secure storage: $e');
    }
  }

  Future<void> syncFromApi({
    String? roomId,
    String? search,
    bool skipHydration = false,
  }) async {
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

      _logger
          .i('Syncing tenants from API with roomId: $roomId, search: $search');
      final queryParams = <String, String>{};
      if (roomId != null) queryParams['roomId'] = roomId;
      if (search != null) queryParams['search'] = search;

      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/tenants',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) {
        _logger.w('Request cancelled due to network loss');
        return;
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> tenantsJson = response.data['data'];
        _tenantCache = tenantsJson.map((json) {
          final tenantDto = TenantDto.fromJson(json);
          final tenant = tenantDto.toTenant();

          // Reconstruct room and building references
          if (tenantDto.room != null) {
            tenant.room = tenantDto.room!.toRoom();
            if (tenantDto.room!.building != null) {
              tenant.room!.building = tenantDto.room!.building!.toBuilding();
            }
            // Set bidirectional reference
            if (tenant.room != null) {
              tenant.room!.tenant = tenant;
            }
          }

          return tenant;
        }).toList();

        if (!skipHydration) {
          await save();
        }
        _logger.i('Synced ${_tenantCache.length} tenants from API');
      }
    } catch (e) {
      _logger.e('Failed to sync tenants from API: $e');
    }
  }

  Future<Tenant> createTenant({
    required String name,
    required String phoneNumber,
    required Gender gender,
    String? roomId,
  }) async {
    try {
      Tenant createdTenant;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Creating tenant via API: $name');

          String genderStr;
          switch (gender) {
            case Gender.male:
              genderStr = 'male';
              break;
            case Gender.female:
              genderStr = 'female';
              break;
            default:
              genderStr = 'other';
          }

          final requestData = {
            'name': name,
            'phoneNumber': phoneNumber,
            'gender': genderStr,
            if (roomId != null) 'roomId': roomId,
          };

          final response = await _apiHelper.dio.post(
            '${_apiHelper.baseUrl}/tenants',
            data: requestData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] == true) {
            _logger.w('Request cancelled, saving locally');
            createdTenant = Tenant(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              phoneNumber: phoneNumber,
              gender: gender,
              room: null,
            );
            _tenantCache.add(createdTenant);
            await save();
            return createdTenant;
          }

          if (response.statusCode == 201 && response.data['success'] == true) {
            final tenantDto = TenantDto.fromJson(response.data['data']);
            createdTenant = tenantDto.toTenant();

            // Reconstruct room and building references
            if (tenantDto.room != null) {
              createdTenant.room = tenantDto.room!.toRoom();
              if (tenantDto.room!.building != null) {
                createdTenant.room!.building =
                    tenantDto.room!.building!.toBuilding();
              }
              // Set bidirectional reference
              if (createdTenant.room != null) {
                createdTenant.room!.tenant = createdTenant;
              }
            }

            _tenantCache.add(createdTenant);
            await save();
            _logger.i('Tenant created successfully via API');
            return createdTenant;
          } else {
            throw Exception(
                'Failed to create tenant via API: ${response.statusCode}');
          }
        }
      }

      // Offline creation
      _logger.i('Creating tenant offline: $name');
      createdTenant = Tenant(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        room: null,
      );
      _tenantCache.add(createdTenant);
      await save();
      return createdTenant;
    } catch (e) {
      _logger.e('Failed to create tenant: $e');
      throw Exception('Failed to create tenant: $e');
    }
  }

  Future<Tenant> updateTenant({
    required String id,
    String? name,
    String? phoneNumber,
    Gender? gender,
    String? roomId,
  }) async {
    try {
      final existingTenant = _tenantCache.firstWhere(
        (tenant) => tenant.id == id,
        orElse: () => throw Exception('Tenant not found in cache: $id'),
      );

      Tenant updatedTenant;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating tenant via API: $id');

          String? genderStr;
          if (gender != null) {
            switch (gender) {
              case Gender.male:
                genderStr = 'male';
                break;
              case Gender.female:
                genderStr = 'female';
                break;
              default:
                genderStr = 'other';
            }
          }

          final requestData = <String, dynamic>{};
          if (name != null) requestData['name'] = name;
          if (phoneNumber != null) requestData['phoneNumber'] = phoneNumber;
          if (genderStr != null) requestData['gender'] = genderStr;
          if (roomId != null) requestData['roomId'] = roomId;

          final response = await _apiHelper.dio.put(
            '${_apiHelper.baseUrl}/tenants/$id',
            data: requestData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] == true) {
            _logger.w('Request cancelled, updating locally');
            updatedTenant = existingTenant.copyWith(
              name: name,
              phoneNumber: phoneNumber,
              gender: gender,
              room: roomId == null ? existingTenant.room : null,
            );
            final index = _tenantCache.indexWhere((t) => t.id == id);
            if (index >= 0) {
              _tenantCache[index] = updatedTenant;
              // Set bidirectional reference
              if (updatedTenant.room != null) {
                updatedTenant.room!.tenant = updatedTenant;
              }
            }
            await save();
            return updatedTenant;
          }

          if (response.statusCode == 200 && response.data['success'] == true) {
            final tenantDto = TenantDto.fromJson(response.data['data']);
            updatedTenant = tenantDto.toTenant();

            // Reconstruct room and building references
            if (tenantDto.room != null) {
              updatedTenant.room = tenantDto.room!.toRoom();
              if (tenantDto.room!.building != null) {
                updatedTenant.room!.building =
                    tenantDto.room!.building!.toBuilding();
              }
            } else if (existingTenant.room != null && roomId == null) {
              // Preserve existing room if not explicitly changed
              updatedTenant.room = existingTenant.room;
            }
            // Set bidirectional reference
            if (updatedTenant.room != null) {
              updatedTenant.room!.tenant = updatedTenant;
            }

            final index = _tenantCache.indexWhere((t) => t.id == id);
            if (index >= 0) {
              _tenantCache[index] = updatedTenant;
            } else {
              _tenantCache.add(updatedTenant);
            }
            await save();
            _logger.i('Tenant updated successfully via API: $id');
            return updatedTenant;
          } else {
            throw Exception(
                'Failed to update tenant via API: ${response.statusCode}');
          }
        }
      }

      // Offline update
      updatedTenant = existingTenant.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        room: roomId == null ? existingTenant.room : null,
      );
      // Set bidirectional reference
      if (updatedTenant.room != null) {
        updatedTenant.room!.tenant = updatedTenant;
      }
      final index = _tenantCache.indexWhere((t) => t.id == id);
      if (index >= 0) {
        _tenantCache[index] = updatedTenant;
      }
      await save();
      _logger.i('Tenant updated locally: $id');
      return updatedTenant;
    } catch (e) {
      _logger.e('Failed to update tenant: $e');
      throw Exception('Failed to update tenant: $e');
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting tenant via API: $id');
          final response = await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}/tenants/$id',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode != 200) {
            throw Exception(
                'Failed to delete tenant via API: ${response.statusCode}');
          }
        }
      }

      _tenantCache.removeWhere((tenant) => tenant.id == id);
      await save();
      _logger.i('Tenant deleted successfully: $id');
    } catch (e) {
      _logger.e('Failed to delete tenant: $e');
      throw Exception('Failed to delete tenant: $e');
    }
  }

  Future<Tenant?> getTenantById(String id) async {
    try {
      // Check cache first
      try {
        return _tenantCache.firstWhere((tenant) => tenant.id == id);
      } catch (e) {
        // Not in cache, try API if online
      }

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Fetching tenant from API: $id');
          final response = await _apiHelper.dio.get(
            '${_apiHelper.baseUrl}/tenants/$id',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.statusCode == 200 && response.data['success'] == true) {
            final tenantDto = TenantDto.fromJson(response.data['data']);
            final tenant = tenantDto.toTenant();

            // Reconstruct room and building references
            if (tenantDto.room != null) {
              tenant.room = tenantDto.room!.toRoom();
              if (tenantDto.room!.building != null) {
                tenant.room!.building = tenantDto.room!.building!.toBuilding();
              }
              // Set bidirectional reference
              if (tenant.room != null) {
                tenant.room!.tenant = tenant;
              }
            }

            // Update cache
            final index = _tenantCache.indexWhere((t) => t.id == id);
            if (index >= 0) {
              _tenantCache[index] = tenant;
            } else {
              _tenantCache.add(tenant);
            }
            await save();

            return tenant;
          }
        }
      }

      return null;
    } catch (e) {
      _logger.e('Failed to get tenant by id: $e');
      return null;
    }
  }

  Future<void> restoreTenant(int restoreIndex, Tenant tenant) async {
    if (restoreIndex >= 0 && restoreIndex <= _tenantCache.length) {
      _tenantCache.insert(restoreIndex, tenant);
      await save();
      _logger.i('Tenant restored at index $restoreIndex: ${tenant.id}');
    } else {
      throw Exception('Invalid restore index: $restoreIndex');
    }
  }

  Future<void> removeRoom(String tenantId) async {
    final tenant = _tenantCache.firstWhere(
      (tenant) => tenant.id == tenantId,
      orElse: () => throw Exception('Tenant not found: $tenantId'),
    );

    await updateTenant(
      id: tenantId,
      name: tenant.name,
      phoneNumber: tenant.phoneNumber,
      gender: tenant.gender,
      roomId: null, // This will remove the room assignment
    );
  }

  List<Tenant> getAllTenants() {
    return List.unmodifiable(_tenantCache);
  }

  List<Tenant> getTenantsByRoom(String roomId) {
    return _tenantCache.where((tenant) => tenant.room?.id == roomId).toList();
  }

  List<Tenant> getTenantsByBuilding(String buildingId) {
    try {
      return _tenantCache.where((tenant) {
        return tenant.room != null && tenant.room!.building?.id == buildingId;
      }).toList();
    } catch (e) {
      _logger.e('Failed to retrieve tenants for building $buildingId: $e');
      throw Exception(
          'Failed to retrieve tenants for building $buildingId: $e');
    }
  }

  List<Tenant> searchTenants(String query) {
    final lowerQuery = query.toLowerCase();
    return _tenantCache.where((tenant) {
      return tenant.name.toLowerCase().contains(lowerQuery) ||
          tenant.phoneNumber.contains(query);
    }).toList();
  }

  int getTenantCount() {
    return _tenantCache.length;
  }

  int getTenantCountByBuilding(String buildingId) {
    return getTenantsByBuilding(buildingId).length;
  }
}
