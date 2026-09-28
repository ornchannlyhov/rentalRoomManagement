import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/pull_merge.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/dtos/tenant_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

class TenantRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Tenant> _tenantCache = [];

  TenantRepository(this._databaseService);

  Future<void> load() async {
    try {
      final tenantsList = _databaseService.tenantsBox.values.toList();
      _tenantCache = tenantsList.map((e) {
        final tenantDto = TenantDto.fromJson(Map<String, dynamic>.from(e));
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
    } catch (e) {
      throw Exception('Failed to load tenant data: $e');
    }
  }

  Future<void> loadWithoutHydration() async {
    final tenantsList = _databaseService.tenantsBox.values.toList();
    _tenantCache = tenantsList
        .map((e) => TenantDto.fromJson(Map<String, dynamic>.from(e)).toTenant())
        .toList();
  }

  Future<void> save() async {
    try {
      final records = <String, Map<String, dynamic>>{};
      for (var i = 0; i < _tenantCache.length; i++) {
        final tenant = _tenantCache[i];
        final dto = TenantDto(
          id: tenant.id,
          name: tenant.name,
          phoneNumber: tenant.phoneNumber,
          gender: _genderToString(tenant.gender),
          chatId: tenant.chatId,
          language: tenant.language,
          deposit: tenant.deposit,
          tenantProfile: tenant.tenantProfile,
          roomId: tenant.room?.id,
          // Do NOT save full objects
          room: null,
        );
        records[_tenantCache[i].id] = Map<String, dynamic>.from(dto.toJson());
      }

      await _databaseService.writeRecords(
          _databaseService.tenantsBox, records);
    } catch (e) {
      throw Exception('Failed to save tenant data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.tenantsBox.clear();
    _tenantCache.clear();
  }

  Future<void> syncFromApi({
    String? roomId,
    String? search,
    bool skipHydration = false,
  }) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

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
      _tenantCache = mergePulled(
        server: result.data!,
        local: _tenantCache,
        idOf: (item) => item.id,
      );
      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint, {
    String? filePath,
    String? fileFieldName,
  }) async {
    await Outbox.instance.enqueue(
      entity: 'tenant',
      type: type,
      endpoint: endpoint,
      data: data,
      filePath: filePath,
      fileFieldName: fileFieldName,
    );
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
