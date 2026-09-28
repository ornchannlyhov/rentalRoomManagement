import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/pull_merge.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/data/dtos/service_dto.dart';
import 'package:joul_v2/core/services/database_service.dart';

class ServiceRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Service> _serviceCache = [];

  ServiceRepository(this._databaseService);

  Future<void> load() async {
    try {
      final servicesList = _databaseService.servicesBox.values.toList();
      _serviceCache = servicesList
          .map((e) =>
              ServiceDto.fromJson(Map<String, dynamic>.from(e)).toService())
          .toList();
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
  }

  Future<void> save() async {
    try {
      final records = <String, Map<String, dynamic>>{};
      for (var i = 0; i < _serviceCache.length; i++) {
        final dto = ServiceDto(
          id: _serviceCache[i].id,
          name: _serviceCache[i].name,
          price: _serviceCache[i].price,
          buildingId: _serviceCache[i].buildingId,
        );
        records[_serviceCache[i].id] = Map<String, dynamic>.from(dto.toJson());
      }

      await _databaseService.writeRecords(
          _databaseService.servicesBox, records);
    } catch (e) {
      throw Exception('Failed to save service data: $e');
    }
  }

  Future<void> clear() async {
    await _databaseService.servicesBox.clear();
    _serviceCache.clear();
  }

  Future<void> syncFromApi({bool skipHydration = false}) async {
    if (!await _apiHelper.hasNetwork()) {
      return;
    }

    final result = await _syncHelper.fetch<Service>(
      endpoint: '/services',
      fromJsonList: (jsonList) => jsonList
          .map((json) => ServiceDto.fromJson(json).toService())
          .toList(),
    );

    if (result.success && result.data != null) {
      _serviceCache = mergePulled(
        server: result.data!,
        local: _serviceCache,
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
    String endpoint,
  ) async {
    await Outbox.instance.enqueue(
      entity: 'service',
      type: type,
      endpoint: endpoint,
      data: data,
    );
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

}
