// ignore_for_file: unused_field

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/repositories/service_repository.dart';
import 'package:receipts_v2/data/repositories/building_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/data/repositories/tenant_repository.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/dtos/receipt_dto.dart';
import 'package:receipts_v2/data/dtos/room_dto.dart';
import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:receipts_v2/data/dtos/service_dto.dart';
import 'package:dio/dio.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/helpers/sync_operation_helper.dart';

// --- Top-level compute helpers ---
List<Receipt> _parseReceipts(String jsonString) {
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData
      .map((json) =>
          ReceiptDto.fromJson(json as Map<String, dynamic>).toReceipt())
      .toList();
}

String _encodeReceipts(List<Receipt> receipts) {
  return jsonEncode(receipts.map((receipt) {
    // Convert PaymentStatus enum to string
    final statusStr = receipt.paymentStatus.name.toLowerCase();

    final receiptDto = ReceiptDto(
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
      room: receipt.room != null
          ? RoomDto(
              id: receipt.room!.id,
              roomNumber: receipt.room!.roomNumber,
              roomStatus: receipt.room!.roomStatus.toString().split('.').last,
              price: receipt.room!.price,
              buildingId: receipt.room!.building?.id,
              building: receipt.room!.building != null
                  ? BuildingDto(
                      id: receipt.room!.building!.id,
                      name: receipt.room!.building!.name,
                      rentPrice: receipt.room!.building!.rentPrice,
                      electricPrice: receipt.room!.building!.electricPrice,
                      waterPrice: receipt.room!.building!.waterPrice,
                    )
                  : null,
            )
          : null,
      services: receipt.services.isNotEmpty
          ? receipt.services
              .map((service) => ServiceDto(
                    id: service.id,
                    name: service.name,
                    price: service.price,
                    buildingId: service.buildingId,
                  ))
              .toList()
          : null,
      serviceIds: receipt.serviceIds.isNotEmpty ? receipt.serviceIds : null,
    );

    return receiptDto.toJson();
  }).toList());
}

List<Map<String, dynamic>> _parsePendingChanges(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

class ReceiptRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'receipt_secure_data';
  final String pendingChangesKey = 'receipt_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final SyncOperationHelper _syncHelper = SyncOperationHelper();

  List<Receipt> _receiptCache = [];
  List<Map<String, dynamic>> _pendingChanges = [];

  final ServiceRepository _serviceRepository;
  final BuildingRepository _buildingRepository;
  final RoomRepository _roomRepository;
  final TenantRepository _tenantRepository;

  ReceiptRepository(
    this._serviceRepository,
    this._buildingRepository,
    this._roomRepository,
    this._tenantRepository,
  );

  // UPDATED: Remove hydration from load()
  Future<void> load() async {
    final jsonString = await _secureStorage.read(key: storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      _receiptCache = await compute(_parseReceipts, jsonString);
    } else {
      _receiptCache = [];
    }

    final pendingString = await _secureStorage.read(key: pendingChangesKey);
    if (pendingString != null && pendingString.isNotEmpty) {
      _pendingChanges = await compute(_parsePendingChanges, pendingString);
    } else {
      _pendingChanges = [];
    }

    await updateStatusToOverdue();
  }

  Future<void> save() async {
    if (_receiptCache.isNotEmpty) {
      final jsonString = await compute(_encodeReceipts, _receiptCache);
      await _secureStorage.write(key: storageKey, value: jsonString);
    }

    if (_pendingChanges.isNotEmpty) {
      final pendingJson = jsonEncode(_pendingChanges);
      await _secureStorage.write(key: pendingChangesKey, value: pendingJson);
    }
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: storageKey);
    await _secureStorage.delete(key: pendingChangesKey);
    _receiptCache.clear();
    _pendingChanges.clear();
  }

  Future<void> syncFromApi({
    String? roomId,
    String? tenantId,
    String? buildingId,
    PaymentStatus? paymentStatus,
    bool skipHydration = false,
  }) async {
    if (!await _apiHelper.hasNetwork()) return;

    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) return;

    await _syncPendingChanges();

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

    final response = await _apiHelper.dio.get(
      '${_apiHelper.baseUrl}/receipts',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      cancelToken: _apiHelper.cancelToken,
    );

    if (response.data['cancelled'] == true) return;

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> receiptsJson = response.data['data'];
      _receiptCache = receiptsJson.map((json) {
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

      await updateStatusToOverdue();

      if (!skipHydration) {
        await save();
      }
    }
  }

  Future<void> _syncPendingChanges() async {
    if (_pendingChanges.isEmpty) return;

    final successfulChanges = <int>[];
    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final success = await _syncHelper.applyPendingChange(change);
      if (success) successfulChanges.add(i);
    }

    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
      await _secureStorage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
    }
  }

  Future<void> _addPendingChange(
    String type,
    Map<String, dynamic> data,
    String endpoint,
  ) async {
    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> createReceipt(Receipt newReceipt,
      {Uint8List? receiptImage}) async {
    if (newReceipt.room == null) {
      throw Exception('Receipt must have a room reference');
    }
    if (newReceipt.room!.building == null) {
      throw Exception('Room must have a building reference');
    }

    // CRITICAL FIX: Extract serviceIds and convert to JSON string
    final serviceIds = newReceipt.services.isNotEmpty
        ? newReceipt.services.map((s) => s.id).toList()
        : newReceipt.serviceIds;

    final requestData = {
      'roomId': newReceipt.room!.id,
      'date': newReceipt.date.toIso8601String(),
      'dueDate': newReceipt.dueDate.toIso8601String(),
      'lastWaterUsed': newReceipt.lastWaterUsed,
      'lastElectricUsed': newReceipt.lastElectricUsed,
      'thisWaterUsed': newReceipt.thisWaterUsed,
      'thisElectricUsed': newReceipt.thisElectricUsed,
      'paymentStatus': newReceipt.paymentStatus.toString().split('.').last,
      'serviceIds': jsonEncode(serviceIds),
    };

    bool syncedOnline = false;
    Receipt? createdReceipt;

    if (await _apiHelper.hasNetwork()) {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null && newReceipt.room?.id != null) {
        try {
          Response response;
          if (receiptImage != null) {
            final formData = FormData.fromMap({
              ...requestData,
              'receiptImage': MultipartFile.fromBytes(
                receiptImage,
                filename: 'receipt_${newReceipt.id}.png',
              ),
            });

            response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}/receipts',
              data: formData,
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                contentType: 'multipart/form-data',
              ),
              cancelToken: _apiHelper.cancelToken,
            );
          } else {
            response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}/receipts',
              data: requestData,
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );
          }

          if (response.data['cancelled'] != true &&
              response.statusCode == 201 &&
              response.data['success'] == true) {
            final dto = ReceiptDto.fromJson(response.data['data']);
            createdReceipt = dto.toReceipt();
            createdReceipt.room = newReceipt.room;
            syncedOnline = true;
          }
        } catch (_) {}
      }
    }

    createdReceipt ??= newReceipt;

    final existingIndex = _receiptCache.indexWhere((receipt) =>
        receipt.room?.id == newReceipt.room?.id &&
        receipt.date.year == newReceipt.date.year &&
        receipt.date.month == newReceipt.date.month);

    if (existingIndex != -1) {
      _receiptCache[existingIndex] = createdReceipt;
    } else {
      _receiptCache.add(createdReceipt);
    }

    if (!syncedOnline) {
      await _addPendingChange('create', requestData, '/receipts');
    }

    await save();
  }

  Future<void> updateReceipt(Receipt updatedReceipt) async {
    final serviceIds = updatedReceipt.services.isNotEmpty
        ? updatedReceipt.services.map((s) => s.id).toList()
        : updatedReceipt.serviceIds;

    final requestData = {
      if (updatedReceipt.room?.id != null) 'roomId': updatedReceipt.room!.id,
      'date': updatedReceipt.date.toIso8601String(),
      'dueDate': updatedReceipt.dueDate.toIso8601String(),
      'lastWaterUsed': updatedReceipt.lastWaterUsed,
      'lastElectricUsed': updatedReceipt.lastElectricUsed,
      'thisWaterUsed': updatedReceipt.thisWaterUsed,
      'thisElectricUsed': updatedReceipt.thisElectricUsed,
      'paymentStatus': updatedReceipt.paymentStatus.toString().split('.').last,
      'serviceIds': jsonEncode(serviceIds),
    };

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
      addPendingChange: (type, data) =>
          _addPendingChange(type, data, '/receipts/${updatedReceipt.id}'),
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
      addPendingChange: (type, data) =>
          _addPendingChange(type, data, '/receipts/$receiptId'),
    );
    await save();
  }

  Future<void> deleteLastYearReceipts() async {
    final now = DateTime.now();
    final startOfCurrentYear = DateTime(now.year, 1, 1);
    _receiptCache.removeWhere((r) => r.date.isBefore(startOfCurrentYear));
    await save();
  }

  Future<void> restoreReceipt(int index, Receipt receipt) async {
    if (index >= 0 && index <= _receiptCache.length) {
      _receiptCache.insert(index, receipt);
      await save();
    } else {
      throw Exception('Invalid index for restoring receipt.');
    }
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

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;
}
