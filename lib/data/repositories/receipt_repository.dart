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
import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/dtos/building_dto.dart';
import 'package:joul_v2/data/dtos/service_dto.dart';
import 'package:dio/dio.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/core/helpers/sync_operation_helper.dart';

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

  Future<void> load() async {
    final jsonString = await _apiHelper.storage.read(key: storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      _receiptCache = await compute(_parseReceipts, jsonString);
    } else {
      _receiptCache = [];
    }

    final pendingString = await _apiHelper.storage.read(key: pendingChangesKey);
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
      await _apiHelper.storage.write(key: storageKey, value: jsonString);
    }

    if (_pendingChanges.isNotEmpty) {
      final pendingJson = jsonEncode(_pendingChanges);
      await _apiHelper.storage
          .write(key: pendingChangesKey, value: pendingJson);
    }
  }

  Future<void> clear() async {
    await _apiHelper.storage.delete(key: storageKey);
    await _apiHelper.storage.delete(key: pendingChangesKey);
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

    final token = await _apiHelper.storage.read(key: 'auth_token');
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
    final failedChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      final retryCount = change['retryCount'] ?? 0;

      // Max 5 retries for failed changes
      if (retryCount >= 5) {
        failedChanges.add(i);
        if (kDebugMode) {
          print(
              'Receipt pending change exceeded retry limit: ${change['type']} ${change['endpoint']}');
        }
        continue;
      }

      final success = await _syncHelper.applyPendingChange(change);

      if (success) {
        successfulChanges.add(i);
        if (kDebugMode) {
          print(
              'Successfully synced receipt pending change: ${change['type']} ${change['endpoint']}');
        }
      } else {
        // Increment retry count
        _pendingChanges[i]['retryCount'] = retryCount + 1;
        if (kDebugMode) {
          print(
              'Failed to sync receipt pending change (retry ${retryCount + 1}/5): ${change['type']} ${change['endpoint']}');
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
    String endpoint,
  ) async {
    // Check for duplicate pending changes
    final isDuplicate = _pendingChanges.any((change) {
      if (change['type'] != type || change['endpoint'] != endpoint) {
        return false;
      }

      // For creates with localId, check if localId matches
      if (type == 'create' && data['localId'] != null) {
        return change['data']['localId'] == data['localId'];
      }

      // For updates/deletes, check if id matches
      if (data['id'] != null) {
        return change['data']['id'] == data['id'];
      }

      // For receipts, also check by roomId and date combination
      if (data['roomId'] != null && data['date'] != null) {
        return change['data']['roomId'] == data['roomId'] &&
            change['data']['date'] == data['date'];
      }

      // Fallback: compare full data
      return jsonEncode(change['data']) == jsonEncode(data);
    });

    if (isDuplicate) {
      if (kDebugMode) {
        print('Skipping duplicate receipt pending change: $type $endpoint');
      }
      return;
    }

    _pendingChanges.add({
      'type': type,
      'data': data,
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });

    if (kDebugMode) {
      print('Added receipt pending change: $type $endpoint');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCurrentMonthUsage() async {
    final token = await _apiHelper.storage.read(key: 'auth_token');
    if (token == null) return [];

    try {
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/usage/current-month',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) return [];

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<int> generateReceiptsFromUsage({
    Future<Uint8List?> Function(Receipt)? createImage,
  }) async {
    final usageData = await _fetchCurrentMonthUsage();
    if (usageData.isEmpty) return 0;

    int generatedCount = 0;
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final yearOfLastMonth = now.month == 1 ? now.year - 1 : now.year;
    final lastMonthReceipts = getReceiptsByMonth(yearOfLastMonth, lastMonth);

    // Track rooms that already have receipts for current month
    final currentMonthReceipts = getReceiptsForCurrentMonth();
    final roomsWithReceipts = currentMonthReceipts
        .map((r) => r.room?.roomNumber)
        .where((rn) => rn != null)
        .toSet();

    for (var usage in usageData) {
      try {
        final String roomNumber = usage['roomNumber']?.toString() ?? '';
        if (roomNumber.isEmpty) continue;

        // Skip if receipt already exists for this room this month
        if (roomsWithReceipts.contains(roomNumber)) continue;

        final room = _roomRepository.getAllRooms().firstWhere(
              (r) => r.roomNumber == roomNumber,
              orElse: () => throw Exception('Room $roomNumber not found'),
            );

        final lastReceipt = lastMonthReceipts.firstWhere(
          (r) => r.room?.roomNumber == roomNumber,
          orElse: () => Receipt(
            id: '',
            date: DateTime.now(),
            dueDate: DateTime.now(),
            lastWaterUsed: 0,
            lastElectricUsed: 0,
            thisWaterUsed: 0,
            thisElectricUsed: 0,
            paymentStatus: PaymentStatus.pending,
          ),
        );

        // Use services from last month's receipt
        List<Service> servicesForReceipt;

        if (lastReceipt.id.isNotEmpty && lastReceipt.services.isNotEmpty) {
          // Use services from last month's receipt
          servicesForReceipt = List<Service>.from(lastReceipt.services);
        } else {
          // Fallback: If no last receipt, get all building services
          servicesForReceipt = [];
        }

        int parseUsage(dynamic value) {
          if (value == null) return 0;
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            return double.tryParse(value)?.toInt() ?? 0;
          }
          return 0;
        }

        final int thisWater = parseUsage(usage['waterUsage']);
        final int thisElectric = parseUsage(usage['electricityUsage']);

        final newReceipt = Receipt(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}_$roomNumber',
          date: now,
          dueDate: DateTime(now.year, now.month + 1, 5),
          lastWaterUsed: lastReceipt.thisWaterUsed,
          lastElectricUsed: lastReceipt.thisElectricUsed,
          thisWaterUsed: thisWater,
          thisElectricUsed: thisElectric,
          paymentStatus: PaymentStatus.pending,
          room: room,
          services: servicesForReceipt,
        );

        Uint8List? imageBytes;
        if (createImage != null) {
          try {
            imageBytes = await createImage(newReceipt);
          } catch (e) {
            imageBytes = null;
          }
        }

        await createReceipt(newReceipt, receiptImage: imageBytes);
        generatedCount++;
      } catch (e) {
        continue;
      }
    }

    return generatedCount;
  }

  Future<void> createReceipt(Receipt newReceipt,
      {Uint8List? receiptImage}) async {
    if (newReceipt.room == null) {
      throw Exception('Receipt must have a room reference');
    }
    if (newReceipt.room!.building == null) {
      throw Exception('Room must have a building reference');
    }

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

    await _syncHelper.create<Receipt>(
      endpoint: '/receipts',
      data: requestData,
      fromJson: (json) {
        final dto = ReceiptDto.fromJson(json);
        final receipt = dto.toReceipt();
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

  bool hasPendingChanges() => _pendingChanges.isNotEmpty;
  int getPendingChangesCount() => _pendingChanges.length;

  /// Get list of pending changes for debugging/display
  List<Map<String, dynamic>> getPendingChanges() {
    return List.unmodifiable(_pendingChanges);
  }
}
