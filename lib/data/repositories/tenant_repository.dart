import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/dtos/tenant_dto.dart';
import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/dtos/building_dto.dart';

// Top-level functions for compute() isolation
List<Tenant> _parseTenants(String jsonString) {
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData.map((json) {
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
}

String _encodeTenants(List<Tenant> tenants) {
  String genderToString(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      default:
        return 'other';
    }
  }

  return jsonEncode(tenants
      .map((tenant) => TenantDto(
            id: tenant.id,
            name: tenant.name,
            phoneNumber: tenant.phoneNumber,
            gender: genderToString(tenant.gender),
            chatId: tenant.chatId,
            language: tenant.language,
            deposit: tenant.deposit,
            tenantProfile: tenant.tenantProfile,
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
                            appUserId: tenant.room!.building!.appUserId,
                            name: tenant.room!.building!.name,
                            rentPrice: tenant.room!.building!.rentPrice,
                            electricPrice: tenant.room!.building!.electricPrice,
                            waterPrice: tenant.room!.building!.waterPrice,
                            buildingImages:
                                tenant.room!.building!.buildingImages,
                            services: tenant.room!.building!.services,
                            passKey: tenant.room!.building!.passKey,
                          )
                        : null,
                  )
                : null,
          ).toJson())
      .toList());
}

List<Map<String, dynamic>> _parsePendingChanges(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

class TenantRepository {
  final String storageKey = 'tenant_secure_data';
  final String pendingChangesKey = 'tenant_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Tenant> _tenantCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  Future<void> load() async {
    try {
      // Load tenants with compute() for better performance
      final jsonString = await _apiHelper.storage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _tenantCache = await compute(_parseTenants, jsonString);
      } else {
        _tenantCache = [];
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
      throw Exception('Failed to load tenant data: $e');
    }
  }

  Future<void> save() async {
    try {
      // Only save if there's actual data
      if (_tenantCache.isNotEmpty) {
        final jsonString = await compute(_encodeTenants, _tenantCache);
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
      throw Exception('Failed to save tenant data: $e');
    }
  }

  Future<void> clear() async {
    await _apiHelper.storage.delete(key: storageKey);
    await _apiHelper.storage.delete(key: pendingChangesKey);
    _tenantCache.clear();
    _pendingChanges.clear();
  }

  Future<void> syncFromApi({
    String? roomId,
    String? search,
    bool skipHydration = false,
  }) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    await _syncPendingChanges();

    // Construct endpoint with query parameters
    String endpoint = '/tenants';
    bool hasQuery = false;
    if (roomId != null || search != null) {
      endpoint += '?';
      hasQuery = true;
    }
    if (roomId != null) {
      endpoint += 'roomId=$roomId';
      hasQuery = true;
    }
    if (search != null) {
      if (hasQuery) endpoint += '&';
      endpoint += 'search=$search';
    }

    final result = await _syncHelper.fetch<Tenant>(
      endpoint: endpoint,
      fromJsonList: (jsonList) => jsonList.map((json) {
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
      }).toList(),
    );

    if (result.success && result.data != null) {
      _tenantCache = result.data!;
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
              'Tenant pending change exceeded retry limit: ${change['type']} ${change['endpoint']}');
        }
        continue;
      }

      final success = await _syncHelper.applyPendingChange(change);

      if (success) {
        successfulChanges.add(i);
        if (kDebugMode) {
          print(
              'Successfully synced tenant pending change: ${change['type']} ${change['endpoint']}');
        }
      } else {
        // Increment retry count
        _pendingChanges[i]['retryCount'] = retryCount + 1;
        if (kDebugMode) {
          print(
              'Failed to sync tenant pending change (retry ${retryCount + 1}/5): ${change['type']} ${change['endpoint']}');
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
      await _apiHelper.storage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint, {
    String? filePath,
    String? fileFieldName,
  }) async {
    // Check for duplicate pending changes
    final isDuplicate = _pendingChanges.any((change) {
      if (change['type'] != type || change['endpoint'] != endpoint) {
        return false;
      }

      if (type == 'create' && data['localId'] != null) {
        return change['data']['localId'] == data['localId'];
      }

      if (data['id'] != null) {
        return change['data']['id'] == data['id'];
      }

      return jsonEncode(change['data']) == jsonEncode(data);
    });

    if (isDuplicate) {
      if (kDebugMode) {
        print('Skipping duplicate pending change: $type $endpoint');
      }
      return;
    }

    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
      if (filePath != null) 'filePath': filePath,
      if (fileFieldName != null) 'fileFieldName': fileFieldName,
    });

    if (kDebugMode) {
      print(
          'Added pending change: $type $endpoint${filePath != null ? ' with file' : ''}');
    }
  }

  Future<Tenant> createTenant(Tenant newTenant) async {
    final requestData = {
      'name': newTenant.name,
      'phoneNumber': newTenant.phoneNumber,
      'gender': _genderToString(newTenant.gender),
      'deposit': newTenant.deposit.toString(),
      if (newTenant.room != null) 'roomId': newTenant.room!.id,
    };

    final result = await _syncHelper.create<Tenant>(
      endpoint: '/tenants',
      data: requestData,
      fromJson: (json) {
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
      },
      addToCache: (tenant) async {
        if (tenant.room != null) {
          tenant.room!.tenant = tenant;
        }
        _tenantCache.add(tenant);
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        {...data, 'localId': newTenant.id},
        endpoint,
        filePath: newTenant.imageFile?.path,
        fileFieldName: 'tenantProfile',
      ),
      offlineModel: newTenant,
      file: newTenant.imageFile,
      fileFieldName: 'tenantProfile',
    );

    await save();
    return result.data ?? newTenant;
  }

  Future<void> updateTenant(Tenant updatedTenant) async {
    final requestData = {
      'name': updatedTenant.name,
      'phoneNumber': updatedTenant.phoneNumber,
      'gender': _genderToString(updatedTenant.gender),
      'deposit': updatedTenant.deposit.toString(),
      if (updatedTenant.room != null) 'roomId': updatedTenant.room!.id,
    };

    await _syncHelper.update(
      endpoint: '/tenants/${updatedTenant.id}',
      data: requestData,
      updateCache: () async {
        final index = _tenantCache.indexWhere((t) => t.id == updatedTenant.id);
        if (index != -1) {
          _tenantCache[index] = updatedTenant;
          if (updatedTenant.room != null) {
            updatedTenant.room!.tenant = updatedTenant;
          }
        } else {
          throw Exception('Tenant not found: ${updatedTenant.id}');
        }
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        data,
        endpoint,
        filePath: updatedTenant.imageFile?.path, 
        fileFieldName: 'tenantProfile', 
      ),
      file: updatedTenant.imageFile, 
      fileFieldName: 'tenantProfile', 
    );

    await save();
  }

  Future<void> deleteTenant(String tenantId) async {
    await _syncHelper.delete(
      endpoint: '/tenants/$tenantId',
      id: tenantId,
      deleteFromCache: () async {
        final index = _tenantCache.indexWhere((t) => t.id == tenantId);
        if (index != -1) {
          final tenant = _tenantCache[index];
          if (tenant.room != null) {
            // Clear tenant reference from room
            tenant.room!.tenant = null;
          }
          _tenantCache.removeAt(index);
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

  Future<void> removeRoom(String tenantId) async {
    final index = _tenantCache.indexWhere((t) => t.id == tenantId);
    if (index == -1) {
      throw Exception('Tenant not found: $tenantId');
    }

    final currentTenant = _tenantCache[index];
    final updatedTenant = currentTenant.copyWith(room: null);

    final requestData = {
      'name': updatedTenant.name,
      'phoneNumber': updatedTenant.phoneNumber,
      'gender': _genderToString(updatedTenant.gender),
    };

    await _syncHelper.update(
      endpoint: '/tenants/$tenantId',
      data: requestData,
      updateCache: () async {
        _tenantCache[index] = updatedTenant;
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        data,
        endpoint,
      ),
    );

    await save();
  }

  List<Tenant> getAllTenants() {
    return List.unmodifiable(_tenantCache);
  }

  List<Tenant> getTenantsByBuilding(String buildingId) {
    return _tenantCache
        .where((tenant) =>
            tenant.room != null && tenant.room!.building?.id == buildingId)
        .toList();
  }

  List<Tenant> searchTenants(String query) {
    final lowerQuery = query.toLowerCase();
    return _tenantCache
        .where((tenant) =>
            tenant.name.toLowerCase().contains(lowerQuery) ||
            tenant.phoneNumber.contains(query))
        .toList();
  }

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;

  /// Get list of pending changes for debugging/display
  List<Map<String, dynamic>> getPendingChanges() {
    return List.unmodifiable(_pendingChanges);
  }

  String _genderToString(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      default:
        return 'other';
    }
  }
}
