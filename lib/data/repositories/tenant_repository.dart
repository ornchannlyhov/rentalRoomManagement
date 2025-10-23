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
  final String pendingChangesKey = 'tenant_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Tenant> _tenantCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  Future<void> load() async {
    try {
      _logger.i('Loading tenants from secure storage');

      // Load tenants
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _tenantCache = jsonData.map((json) {
          final tenantDto = TenantDto.fromJson(json);
          final tenant = tenantDto.toTenant();

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

      // Load pending changes
      final pendingString = await _secureStorage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges =
            List<Map<String, dynamic>>.from(jsonDecode(pendingString));
        _logger.i('Loaded ${_pendingChanges.length} pending tenant changes');
      } else {
        _pendingChanges = [];
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

      // Save pending changes
      if (_pendingChanges.isNotEmpty) {
        await _secureStorage.write(
          key: pendingChangesKey,
          value: jsonEncode(_pendingChanges),
        );
      }

      _logger.d(
          'Saved ${_tenantCache.length} tenants and ${_pendingChanges.length} pending changes to storage');
    } catch (e) {
      _logger.e('Failed to save tenants to secure storage: $e');
      throw Exception('Failed to save tenant data to secure storage: $e');
    }
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

    _logger.i('Syncing ${_pendingChanges.length} pending tenant changes...');
    final successfulChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      try {
        await _applyPendingChange(change);
        successfulChanges.add(i);
      } catch (e) {
        _logger.e('Failed to apply pending tenant change: $e');
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
          'Successfully synced ${successfulChanges.length} pending tenant changes');
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
          '${_apiHelper.baseUrl}/tenants',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'update':
        final tenantId = data['id'];
        final updateData = Map<String, dynamic>.from(data);
        updateData.remove('id');
        await _apiHelper.dio.put(
          '${_apiHelper.baseUrl}/tenants/$tenantId',
          data: updateData,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
      case 'delete':
        await _apiHelper.dio.delete(
          '${_apiHelper.baseUrl}/tenants/${data['id']}',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
    }
  }

  Future<void> syncFromApi({
    String? roomId,
    String? search,
    bool skipHydration = false,
    Function()? onHydrationNeeded,
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

      await _syncPendingChanges();

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

          if (tenantDto.room != null) {
            tenant.room = tenantDto.room!.toRoom();
            if (tenantDto.room!.building != null) {
              tenant.room!.building = tenantDto.room!.building!.toBuilding();
            }
            if (tenant.room != null) {
              tenant.room!.tenant = tenant;
            }
          }

          return tenant;
        }).toList();

        if (!skipHydration) {
          await save();
          if (onHydrationNeeded != null) {
            onHydrationNeeded();
          }
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
    Function()? onHydrationNeeded,
  }) async {
    try {
      Tenant createdTenant;
      bool syncedOnline = false;

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

          try {
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

            if (response.data['cancelled'] != true &&
                response.statusCode == 201 &&
                response.data['success'] == true) {
              final tenantDto = TenantDto.fromJson(response.data['data']);
              createdTenant = tenantDto.toTenant();

              if (tenantDto.room != null) {
                createdTenant.room = tenantDto.room!.toRoom();
                if (tenantDto.room!.building != null) {
                  createdTenant.room!.building =
                      tenantDto.room!.building!.toBuilding();
                }
                if (createdTenant.room != null) {
                  createdTenant.room!.tenant = createdTenant;
                }
              }

              syncedOnline = true;
              _logger.i('Tenant created successfully via API');
            } else {
              throw Exception('API returned unsuccessful response');
            }
          } catch (e) {
            _logger.w('Failed to create tenant online, will sync later: $e');
            createdTenant = Tenant(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              phoneNumber: phoneNumber,
              gender: gender,
              room: null,
            );
          }
        } else {
          createdTenant = Tenant(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            phoneNumber: phoneNumber,
            gender: gender,
            room: null,
          );
        }
      } else {
        _logger.i('Creating tenant offline: $name');
        createdTenant = Tenant(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          phoneNumber: phoneNumber,
          gender: gender,
          room: null,
        );
      }

      _tenantCache.add(createdTenant);

      if (!syncedOnline) {
        await _addPendingChange('create', {
          'name': name,
          'phoneNumber': phoneNumber,
          'gender': gender.toString().split('.').last,
          if (roomId != null) 'roomId': roomId,
          'localId': createdTenant.id,
        });
      }

      await save();

      if (onHydrationNeeded != null) {
        onHydrationNeeded();
      }

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
      bool syncedOnline = false;

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

          try {
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

            if (response.data['cancelled'] != true &&
                response.statusCode == 200 &&
                response.data['success'] == true) {
              final tenantDto = TenantDto.fromJson(response.data['data']);
              updatedTenant = tenantDto.toTenant();

              if (tenantDto.room != null) {
                updatedTenant.room = tenantDto.room!.toRoom();
                if (tenantDto.room!.building != null) {
                  updatedTenant.room!.building =
                      tenantDto.room!.building!.toBuilding();
                }
              } else if (existingTenant.room != null && roomId == null) {
                updatedTenant.room = existingTenant.room;
              }
              if (updatedTenant.room != null) {
                updatedTenant.room!.tenant = updatedTenant;
              }

              syncedOnline = true;
              _logger.i('Tenant updated successfully via API: $id');
            } else {
              throw Exception('API returned unsuccessful response');
            }
          } catch (e) {
            _logger.w('Failed to update tenant online, will sync later: $e');
            updatedTenant = existingTenant.copyWith(
              name: name,
              phoneNumber: phoneNumber,
              gender: gender,
              room: roomId == null ? existingTenant.room : null,
            );
          }
        } else {
          updatedTenant = existingTenant.copyWith(
            name: name,
            phoneNumber: phoneNumber,
            gender: gender,
            room: roomId == null ? existingTenant.room : null,
          );
        }
      } else {
        updatedTenant = existingTenant.copyWith(
          name: name,
          phoneNumber: phoneNumber,
          gender: gender,
          room: roomId == null ? existingTenant.room : null,
        );
      }

      if (updatedTenant.room != null) {
        updatedTenant.room!.tenant = updatedTenant;
      }

      final index = _tenantCache.indexWhere((t) => t.id == id);
      if (index >= 0) {
        _tenantCache[index] = updatedTenant;
      }

      if (!syncedOnline) {
        final changeData = <String, dynamic>{'id': id};
        if (name != null) changeData['name'] = name;
        if (phoneNumber != null) changeData['phoneNumber'] = phoneNumber;
        if (gender != null) {
          changeData['gender'] = gender.toString().split('.').last;
        }
        if (roomId != null) changeData['roomId'] = roomId;

        await _addPendingChange('update', changeData);
      }

      await save();
      _logger.i('Tenant updated in local cache: $id');
      return updatedTenant;
    } catch (e) {
      _logger.e('Failed to update tenant: $e');
      throw Exception('Failed to update tenant: $e');
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      Tenant? deletedTenant = _tenantCache.firstWhere(
        (tenant) => tenant.id == id,
        orElse: () => throw Exception('Tenant not found: $id'),
      );

      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting tenant via API: $id');

          try {
            final response = await _apiHelper.dio.delete(
              '${_apiHelper.baseUrl}/tenants/$id',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Tenant deleted successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to delete tenant online, will sync later: $e');
          }
        }
      }

      if (deletedTenant.room != null) {
        deletedTenant.room!.tenant = null;
      }

      _tenantCache.removeWhere((tenant) => tenant.id == id);

      if (!syncedOnline) {
        await _addPendingChange('delete', {'id': id});
      }

      await save();
      _logger.i('Tenant deleted from local cache: $id');
    } catch (e) {
      _logger.e('Failed to delete tenant: $e');
      throw Exception('Failed to delete tenant: $e');
    }
  }

  Future<Tenant?> getTenantById(String id) async {
    try {
      try {
        return _tenantCache.firstWhere((tenant) => tenant.id == id);
      } catch (e) {
        // Not in cache
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

            if (tenantDto.room != null) {
              tenant.room = tenantDto.room!.toRoom();
              if (tenantDto.room!.building != null) {
                tenant.room!.building = tenantDto.room!.building!.toBuilding();
              }
              if (tenant.room != null) {
                tenant.room!.tenant = tenant;
              }
            }

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
      roomId: null,
    );
  }

  List<Tenant> getAllTenants() {
    return List.unmodifiable(_tenantCache);
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

  bool hasPendingChanges() {
    return _pendingChanges.isNotEmpty;
  }

  int getPendingChangesCount() {
    return _pendingChanges.length;
  }
}
