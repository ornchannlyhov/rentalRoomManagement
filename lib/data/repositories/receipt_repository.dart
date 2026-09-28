// ignore_for_file: unused_field

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/data/repositories/service_repository.dart';
import 'package:joul_v2/data/repositories/building_repository.dart';
import 'package:joul_v2/data/repositories/room_repository.dart';
import 'package:joul_v2/data/repositories/tenant_repository.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/data/models/receipt.dart';
import 'package:joul_v2/data/dtos/receipt_dto.dart';
import 'package:dio/dio.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/core/sync/outbox.dart';
import 'package:joul_v2/core/sync/pull_merge.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';
import 'package:joul_v2/core/services/database_service.dart';

class ReceiptRepository {
  final DatabaseService _databaseService;
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Receipt> _receiptCache = [];

  final ServiceRepository _serviceRepository;
  final BuildingRepository _buildingRepository;
  final RoomRepository _roomRepository;
  final TenantRepository _tenantRepository;

  ReceiptRepository(
    this._databaseService,
    this._serviceRepository,
    this._buildingRepository,
    this._roomRepository,
    this._tenantRepository,
  );

  /// Load with automatic hydration (for standalone use)
  Future<void> load() async {
    await loadWithoutHydration();
    await _hydrateFromCachedRepositories();
    await updateStatusToOverdue();
  }

  /// Load WITHOUT hydration (for use by RepositoryManager)
  Future<void> loadWithoutHydration() async {
    final receiptsList = _databaseService.receiptsBox.values.toList();
    _receiptCache = receiptsList
        .map((e) =>
            ReceiptDto.fromJson(Map<String, dynamic>.from(e)).toReceipt())
        .toList();


    if (kDebugMode) {
      print('📥 Loaded ${_receiptCache.length} receipts from Hive (without hydration)');
    }
  }

  /// Hydrate receipt relationships from cached repositories (for offline use)
  Future<void> _hydrateFromCachedRepositories() async {
    final rooms = _roomRepository.getAllRooms();
    final services = _serviceRepository.getAllServices();
    
    if (rooms.isEmpty || services.isEmpty) {
      // Dependencies not loaded yet, skip hydration
      if (kDebugMode) {
        print('⚠️ Warning: Cannot hydrate receipts - rooms or services not loaded yet');
      }
      return;
    }
    
    final roomMap = {for (var r in rooms) r.id: r};
    final serviceMap = {for (var s in services) s.id: s};
    
    for (var receipt in _receiptCache) {
      // Hydrate room relationship (which includes building and tenant)
      final roomId = receipt.room?.id;
      if (roomId != null && roomMap.containsKey(roomId)) {
        receipt.room = roomMap[roomId];
      }
      
      // Hydrate services
      if (receipt.serviceIds.isNotEmpty) {
        final hydratedServices = <Service>[];
        for (var serviceId in receipt.serviceIds) {
          final service = serviceMap[serviceId];
          if (service != null) {
            hydratedServices.add(service);
          }
        }
        if (hydratedServices.isNotEmpty) {
          receipt.services = hydratedServices;
        }
      }
    }

    if (kDebugMode) {
      print('✅ Hydrated ${_receiptCache.length} receipts from cached repositories');
    }
  }

  Future<void> save() async {
    final records = <String, Map<String, dynamic>>{};
    for (var i = 0; i < _receiptCache.length; i++) {
      final receipt = _receiptCache[i];
      final statusStr = receipt.paymentStatus.name.toLowerCase();
      
      // Only store IDs for relationships, not full objects
      final dto = ReceiptDto(
        id: receipt.id,
        date: receipt.date,
        dueDate: receipt.dueDate,
        lastWaterUsed: receipt.lastWaterUsed,
        lastElectricUsed: receipt.lastElectricUsed,
        thisWaterUsed: receipt.thisWaterUsed,
        thisElectricUsed: receipt.thisElectricUsed,
        paymentStatus: statusStr,
        roomId: receipt.room?.id,
        roomNumber: receipt.room?.roomNumber,
        serviceIds: receipt.serviceIds.isNotEmpty ? receipt.serviceIds : null,
        // Don't store full nested objects - only IDs
      );
      records[_receiptCache[i].id] = Map<String, dynamic>.from(dto.toJson());
    }

    await _databaseService.writeRecords(
        _databaseService.receiptsBox, records);

    if (kDebugMode) {
      print('💾 Saved ${_receiptCache.length} receipts to Hive');
    }
  }

  Future<void> clear() async {
    await _databaseService.receiptsBox.clear();
    _receiptCache.clear();
  }

  Future<void> syncFromApi({
    String? roomId,
    String? tenantId,
    String? buildingId,
    PaymentStatus? paymentStatus,
    bool skipHydration = false,
  }) async {
    if (!await _apiHelper.hasNetwork()) return;

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) return;


    final queryParams = <String, String>{};
    if (roomId != null) queryParams['roomId'] = roomId;
    if (tenantId != null) queryParams['tenantId'] = tenantId;
    if (buildingId != null) queryParams['buildingId'] = buildingId;
    if (paymentStatus != null) {
      String statusStr;
      switch (paymentStatus) {
        case PaymentStatus.paid:
          statusStr = 'paid';
          break;
        case PaymentStatus.overdue:
          statusStr = 'overdue';
          break;
        default:
          statusStr = 'pending';
      }
      queryParams['paymentStatus'] = statusStr;
    }

    final Response response;
    try {
      response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/receipts',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );
    } on DioException catch (e) {
      // Connection lost mid-sync: keep the cached receipts.
      if (e.type == DioExceptionType.badResponse) rethrow;
      return;
    }

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> receiptsJson = response.data['data'];
      final downloaded = receiptsJson.map((json) {
        final dto = ReceiptDto.fromJson(json);
        final receipt = dto.toReceipt();
        if (dto.room != null) {
          receipt.room = dto.room!.toRoom();
          if (dto.room!.building != null) {
            receipt.room!.building = dto.room!.building!.toBuilding();
          }
        }
        return receipt;
      }).toList();
      _receiptCache = mergePulled(
        server: downloaded,
        local: _receiptCache,
        idOf: (item) => item.id,
      );

      await updateStatusToOverdue();

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
      entity: 'receipt',
      type: type,
      endpoint: endpoint,
      data: data,
    );
  }


  Future<void> createReceipt(Receipt newReceipt,
      {Uint8List? receiptImage}) async {
    if (newReceipt.room == null) {
      throw Exception('Receipt must have a room reference');
    }
    if (newReceipt.room!.building == null) {
      throw Exception('Room must have a building reference');
    }
    if (newReceipt.room!.tenant == null) {
      throw Exception('Room must have a tenant reference');
    }

    final serviceIds = newReceipt.services.isNotEmpty
        ? newReceipt.services.map((s) => s.id).toList()
        : newReceipt.serviceIds;

    final requestData = {
      'roomId': newReceipt.room!.id,
      'tenantId': newReceipt.room!.tenant!.id,
      'date': newReceipt.date.toIso8601String(),
      'dueDate': newReceipt.dueDate.toIso8601String(),
      'lastWaterUsed': newReceipt.lastWaterUsed,
      'lastElectricUsed': newReceipt.lastElectricUsed,
      'thisWaterUsed': newReceipt.thisWaterUsed,
      'thisElectricUsed': newReceipt.thisElectricUsed,
      'paymentStatus': newReceipt.paymentStatus.toString().split('.').last,
      'serviceIds': jsonEncode(serviceIds),
    };

    await _syncHelper.create<Receipt>(
      endpoint: '/receipts',
      data: requestData,
      fromJson: (json) {
        final dto = ReceiptDto.fromJson(json);
        final receipt = dto.toReceipt();

        // ALWAYS preserve the room and building from the request to ensure prices are available
        // The API response may not include building prices (electricPrice, waterPrice, rentPrice)
        receipt.room = newReceipt.room;

        return receipt;
      },
      addToCache: (receipt) async {
        final existingIndex = _receiptCache.indexWhere((r) =>
            r.room?.id == receipt.room?.id &&
            r.date.year == receipt.date.year &&
            r.date.month == receipt.date.month);

        if (existingIndex != -1) {
          _receiptCache[existingIndex] = receipt;
        } else {
          _receiptCache.add(receipt);
        }
      },
      addPendingChange: (type, endpoint, data) => _addPendingChange(
        type,
        {
          ...data,
          'localId': newReceipt.id
        }, // Include localId for offline mapping
        endpoint,
      ),
      offlineModel: newReceipt,
    );

    await save();
  }

  Future<void> updateReceipt(Receipt updatedReceipt) async {
    final serviceIds = updatedReceipt.services.isNotEmpty
        ? updatedReceipt.services.map((s) => s.id).toList()
        : updatedReceipt.serviceIds;

    // Find old receipt to preserve tenantId if needed
    Receipt? oldReceipt;
    try {
      oldReceipt = _receiptCache.firstWhere((r) => r.id == updatedReceipt.id);
    } catch (_) {}

    String? tenantIdToUse;
    if (updatedReceipt.room?.tenant?.id != null) {
      tenantIdToUse = updatedReceipt.room!.tenant!.id;
    } else if (oldReceipt != null &&
        oldReceipt.room?.id == updatedReceipt.room?.id &&
        oldReceipt.room?.tenant?.id != null) {
      tenantIdToUse = oldReceipt.room!.tenant!.id;
    }

    if (kDebugMode) {
      print(
          'DEBUG: ReceiptRepository - Updating receipt: ${updatedReceipt.id}');
      print(
          'DEBUG: ReceiptRepository - updatedReceipt.room.tenant.id: ${updatedReceipt.room?.tenant?.id}');
      print(
          'DEBUG: ReceiptRepository - oldReceipt.room.tenant.id: ${oldReceipt?.room?.tenant?.id}');
      print('DEBUG: ReceiptRepository - Tenant ID to use: $tenantIdToUse');
    }

    final requestData = {
      if (updatedReceipt.room?.id != null) 'roomId': updatedReceipt.room!.id,
      if (tenantIdToUse != null) 'tenantId': tenantIdToUse,
      'date': updatedReceipt.date.toIso8601String(),
      'dueDate': updatedReceipt.dueDate.toIso8601String(),
      'lastWaterUsed': updatedReceipt.lastWaterUsed,
      'lastElectricUsed': updatedReceipt.lastElectricUsed,
      'thisWaterUsed': updatedReceipt.thisWaterUsed,
      'thisElectricUsed': updatedReceipt.thisElectricUsed,
      'paymentStatus': updatedReceipt.paymentStatus.toString().split('.').last,
      'serviceIds': jsonEncode(serviceIds),
    };

    if (kDebugMode) {
      print('DEBUG: ReceiptRepository - Request Data: $requestData');
    }

    await _syncHelper.update(
      endpoint: '/receipts/${updatedReceipt.id}',
      data: requestData,
      updateCache: () async {
        final index =
            _receiptCache.indexWhere((r) => r.id == updatedReceipt.id);
        if (index != -1) {
          final oldReceipt = _receiptCache[index];
          updatedReceipt.room ??= oldReceipt.room;
          if (updatedReceipt.services.isEmpty) {
            updatedReceipt.services = List<Service>.from(oldReceipt.services);
          }
          _receiptCache[index] = updatedReceipt;
        } else {
          throw Exception('Receipt not found: ${updatedReceipt.id}');
        }
      },
      addPendingChange: (type, endpoint, data) =>
          _addPendingChange(type, data, endpoint),
    );

    await save();
  }

  Future<void> deleteReceipt(String receiptId) async {
    await _syncHelper.delete(
      endpoint: '/receipts/$receiptId',
      id: receiptId,
      deleteFromCache: () async {
        _receiptCache.removeWhere((r) => r.id == receiptId);
      },
      addPendingChange: (type, endpoint, data) =>
          _addPendingChange(type, data, endpoint),
    );

    await save();
  }

  /// Confirm receipt and trigger PDF generation/sending
  Future<void> confirmReceipt(String receiptId) async {
    if (!await _apiHelper.hasNetwork()) {
      throw Exception('No internet connection');
    }

    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await _apiHelper.dio.post(
        '${_apiHelper.baseUrl}/receipts/$receiptId/confirm',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to confirm receipt: ${response.statusMessage}');
      }

      if (kDebugMode) {
        print('✅ Receipt confirmed and PDF sent to tenant: $receiptId');
      }
    } on DioException catch (e) {
      if (e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      rethrow;
    }
  }

  Future<void> deleteLastYearReceipts() async {
    final now = DateTime.now();
    final startOfCurrentYear = DateTime(now.year, 1, 1);
    _receiptCache.removeWhere((r) => r.date.isBefore(startOfCurrentYear));
    await save();
  }

  List<Receipt> getAllReceipts() => List.unmodifiable(_receiptCache);

  List<Receipt> getReceiptsForCurrentMonth() {
    final now = DateTime.now();
    return _receiptCache
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .toList();
  }

  List<Receipt> getReceiptsByMonth(int year, int month) {
    return _receiptCache
        .where((r) => r.date.year == year && r.date.month == month)
        .toList();
  }

  Future<void> updateStatusToOverdue() async {
    final now = DateTime.now();
    bool updated = false;

    for (var i = 0; i < _receiptCache.length; i++) {
      final r = _receiptCache[i];
      if (r.paymentStatus != PaymentStatus.paid && r.dueDate.isBefore(now)) {
        _receiptCache[i] = r.copyWith(paymentStatus: PaymentStatus.overdue);
        updated = true;
      }
    }
    if (updated) await save();
  }

  List<Receipt> getReceiptsByBuilding(String buildingId) {
    return _receiptCache
        .where((r) => r.room?.building?.id == buildingId)
        .toList();
  }

}