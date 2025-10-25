import 'dart:convert';
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
import 'package:logger/logger.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'dart:typed_data';

import 'package:receipts_v2/helpers/data_hydration_helper.dart';

class ReceiptRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'receipt_secure_data';
  final String pendingChangesKey = 'receipt_pending_changes';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

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

  /// Hydrate all receipt relationships using DataHydrationHelper
  void _hydrateReceipts() {
    try {
      final helper = DataHydrationHelper(
        buildings: _buildingRepository.getAllBuildings(),
        rooms: _roomRepository.getAllRooms(),
        tenants: _tenantRepository.getAllTenants(),
        services: _serviceRepository.getAllServices(),
      );

      helper.hydrateAll(receipts: _receiptCache);
    } catch (e) {
      _logger.e(' Error during receipt hydration: $e');
    }
  }

  Future<void> load() async {
    try {
      _logger.i('Loading receipts from secure storage');

      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _receiptCache = jsonData.map((json) {
          return ReceiptDto.fromJson(json).toReceipt();
        }).toList();
        _logger.i('Loaded ${_receiptCache.length} receipts from storage');
      } else {
        _receiptCache = [];
      }

      _hydrateReceipts();

      final pendingString = await _secureStorage.read(key: pendingChangesKey);
      if (pendingString != null && pendingString.isNotEmpty) {
        _pendingChanges =
            List<Map<String, dynamic>>.from(jsonDecode(pendingString));
        _logger.i('Loaded ${_pendingChanges.length} pending receipt changes');
      } else {
        _pendingChanges = [];
      }

      await updateStatusToOverdue();
    } catch (e) {
      _logger.e('Error loading receipts from secure storage: $e');
      _receiptCache = [];
      _pendingChanges = [];
    }
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(
        _receiptCache.map((receipt) {
          String statusStr;
          switch (receipt.paymentStatus) {
            case PaymentStatus.paid:
              statusStr = 'paid';
              break;
            case PaymentStatus.overdue:
              statusStr = 'overdue';
              break;
            default:
              statusStr = 'pending';
          }

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
                    roomStatus:
                        receipt.room!.roomStatus.toString().split('.').last,
                    price: receipt.room!.price,
                    buildingId: receipt.room!.building?.id,
                    building: receipt.room!.building != null
                        ? BuildingDto(
                            id: receipt.room!.building!.id,
                            name: receipt.room!.building!.name,
                            rentPrice: receipt.room!.building!.rentPrice,
                            electricPrice:
                                receipt.room!.building!.electricPrice,
                            waterPrice: receipt.room!.building!.waterPrice,
                          )
                        : null,
                  )
                : null,
            receiptServices: receipt.services.isNotEmpty
                ? receipt.services
                    .map((service) => ReceiptServiceDto(
                          id: '${receipt.id}_${service.id}',
                          receiptId: receipt.id,
                          serviceId: service.id,
                          service: ServiceDto(
                            id: service.id,
                            name: service.name,
                            price: service.price,
                            buildingId: service.buildingId,
                          ),
                        ))
                    .toList()
                : null,
          );
          return receiptDto.toJson();
        }).toList(),
      );
      await _secureStorage.write(key: storageKey, value: jsonString);

      if (_pendingChanges.isNotEmpty) {
        await _secureStorage.write(
          key: pendingChangesKey,
          value: jsonEncode(_pendingChanges),
        );
      }

      _logger.d(
          'Saved ${_receiptCache.length} receipts and ${_pendingChanges.length} pending changes to storage');
    } catch (e) {
      _logger.e('Failed to save receipts to secure storage: $e');
      throw Exception('Failed to save receipts to secure storage: $e');
    }
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: storageKey);
    await _secureStorage.delete(key: pendingChangesKey);
    _receiptCache.clear();
    _pendingChanges.clear();
    _logger.i('Cleared receipt data from secure storage');
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

    _logger.i('Syncing ${_pendingChanges.length} pending receipt changes...');
    final successfulChanges = <int>[];

    for (int i = 0; i < _pendingChanges.length; i++) {
      final change = _pendingChanges[i];
      try {
        await _applyPendingChange(change);
        successfulChanges.add(i);
      } catch (e) {
        _logger.e('Failed to apply pending receipt change: $e');
      }
    }

    // Remove successfully synced changes
    for (int i = successfulChanges.length - 1; i >= 0; i--) {
      _pendingChanges.removeAt(successfulChanges[i]);
    }

    if (successfulChanges.isNotEmpty) {
      await _secureStorage.write(
        key: pendingChangesKey,
        value: jsonEncode(_pendingChanges),
      );
      _logger.i(
          'Successfully synced ${successfulChanges.length} pending receipt changes');
    }
  }

  Future<void> _applyPendingChange(Map<String, dynamic> change) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) throw Exception('No auth token');

    final type = change['type'];
    final data = change['data'];

    switch (type) {
      case 'create':
        final formData = FormData.fromMap(data);
        await _apiHelper.dio.post(
          '${_apiHelper.baseUrl}/receipts',
          data: formData,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            contentType: 'multipart/form-data',
          ),
        );
        break;
      case 'update':
        final receiptId = data['id'];
        final updateData = Map<String, dynamic>.from(data);
        updateData.remove('id');
        final formData = FormData.fromMap(updateData);
        await _apiHelper.dio.put(
          '${_apiHelper.baseUrl}/receipts/$receiptId',
          data: formData,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            contentType: 'multipart/form-data',
          ),
        );
        break;
      case 'delete':
        await _apiHelper.dio.delete(
          '${_apiHelper.baseUrl}/receipts/${data['id']}',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        break;
    }
  }

  Future<void> syncFromApi({
    String? roomId,
    String? tenantId,
    String? buildingId,
    PaymentStatus? paymentStatus,
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

      await _syncPendingChanges();

      _logger.i('Syncing receipts from API');

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

      if (response.data['cancelled'] == true) {
        _logger.w('Request cancelled due to network loss');
        return;
      }

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> receiptsJson = response.data['data'];

        _receiptCache = receiptsJson.map((json) {
          final receiptDto = ReceiptDto.fromJson(json);
          final receipt = receiptDto.toReceipt();

          if (receiptDto.room != null) {
            receipt.room = receiptDto.room!.toRoom();
            if (receiptDto.room!.building != null) {
              receipt.room!.building = receiptDto.room!.building!.toBuilding();
            }
          }

          return receipt;
        }).toList();

        // CRITICAL: Hydrate all relationships including room.tenant
        _hydrateReceipts();

        if (!skipHydration) {
          await save();
        }
        _logger.i('Synced ${_receiptCache.length} receipts from API');
      }
    } catch (e) {
      _logger.e('Failed to sync receipts from API: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCurrentMonthUsage() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) {
      _logger.w('No auth token found, skipping usage fetch');
      return [];
    }

    try {
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/usage/current-month',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      _logger.e('Failed to fetch usage data: $e');
      return [];
    }
  }

  Future<void> generateReceiptsFromUsage({
    required Future<Uint8List?> Function(Receipt) createImage,
  }) async {
    _logger.i('Starting automatic receipt generation from usage data...');

    final usageData = await _fetchCurrentMonthUsage();
    if (usageData.isEmpty) {
      _logger.i('No usage data found for the current month.');
      return;
    }

    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final yearOfLastMonth = now.month == 1 ? now.year - 1 : now.year;
    final lastMonthReceipts = getReceiptsByMonth(yearOfLastMonth, lastMonth);

    for (var usage in usageData) {
      final String roomNumber = usage['roomNumber'];

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

      final newReceipt = Receipt(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        date: now,
        dueDate: DateTime(now.year, now.month + 1, 5),
        lastWaterUsed: lastReceipt.thisWaterUsed,
        lastElectricUsed: lastReceipt.thisElectricUsed,
        thisWaterUsed: (usage['waterUsage'] as num).toInt(),
        thisElectricUsed: (usage['electricityUsage'] as num).toInt(),
        paymentStatus: PaymentStatus.pending,
        room: lastReceipt.room,
      );

      final Uint8List? imageBytes = await createImage(newReceipt);

      await createReceipt(newReceipt, receiptImage: imageBytes);
    }
    _logger.i('Finished automatic receipt generation.');
  }

  Future<void> createReceipt(Receipt newReceipt,
      {Uint8List? receiptImage}) async {
    try {
      if (newReceipt.room == null) {
        throw Exception('Receipt must have a room reference');
      }
      if (newReceipt.room!.building == null) {
        throw Exception('Room must have a building reference');
      }

      final existingIndex = _receiptCache.indexWhere((receipt) {
        return receipt.room?.roomNumber == newReceipt.room?.roomNumber &&
            receipt.date.year == newReceipt.date.year &&
            receipt.date.month == newReceipt.date.month;
      });

      Receipt createdReceipt = newReceipt;
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null && newReceipt.room?.id != null) {
          _logger.i(
              'Creating receipt via API for room: ${newReceipt.room?.roomNumber}');

          String statusStr;
          switch (newReceipt.paymentStatus) {
            case PaymentStatus.paid:
              statusStr = 'paid';
              break;
            case PaymentStatus.overdue:
              statusStr = 'overdue';
              break;
            default:
              statusStr = 'pending';
          }

          try {
            final formDataMap = {
              'roomId': newReceipt.room!.id,
              'date': newReceipt.date.toIso8601String(),
              'dueDate': newReceipt.dueDate.toIso8601String(),
              'lastWaterUsed': newReceipt.lastWaterUsed,
              'lastElectricUsed': newReceipt.lastElectricUsed,
              'thisWaterUsed': newReceipt.thisWaterUsed,
              'thisElectricUsed': newReceipt.thisElectricUsed,
              'paymentStatus': statusStr,
              if (newReceipt.services.isNotEmpty)
                'serviceIds':
                    jsonEncode(newReceipt.services.map((s) => s.id).toList()),
            };

            if (receiptImage != null) {
              formDataMap['receiptImage'] = MultipartFile.fromBytes(
                receiptImage,
                filename: 'receipt_${newReceipt.id}.png',
              );
            }

            final formData = FormData.fromMap(formDataMap);

            final response = await _apiHelper.dio.post(
              '${_apiHelper.baseUrl}/receipts',
              data: formData,
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                contentType: 'multipart/form-data',
              ),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 201 &&
                response.data['success'] == true) {
              final receiptDto = ReceiptDto.fromJson(response.data['data']);
              createdReceipt = receiptDto.toReceipt();

              createdReceipt.room = newReceipt.room;

              syncedOnline = true;
              _logger.i('Receipt created successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to create receipt online, will sync later: $e');
          }
        }
      }

      if (existingIndex != -1) {
        _receiptCache[existingIndex] = createdReceipt;
      } else {
        _receiptCache.add(createdReceipt);
      }

      if (!syncedOnline) {
        await _addPendingChange('create', {
          'roomId': newReceipt.room!.id,
          'date': newReceipt.date.toIso8601String(),
          'dueDate': newReceipt.dueDate.toIso8601String(),
          'lastWaterUsed': newReceipt.lastWaterUsed,
          'lastElectricUsed': newReceipt.lastElectricUsed,
          'thisWaterUsed': newReceipt.thisWaterUsed,
          'thisElectricUsed': newReceipt.thisElectricUsed,
          'paymentStatus': newReceipt.paymentStatus.toString().split('.').last,
          if (newReceipt.services.isNotEmpty)
            'serviceIds':
                jsonEncode(newReceipt.services.map((s) => s.id).toList()),
          'localId': newReceipt.id,
        });
      }

      _hydrateReceipts();

      await save();
    } catch (e) {
      _logger.e('Failed to create receipt: $e');
      throw Exception('Failed to create receipt: $e');
    }
  }

  Future<void> updateReceipt(Receipt updatedReceipt) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Updating receipt via API: ${updatedReceipt.id}');

          String statusStr;
          switch (updatedReceipt.paymentStatus) {
            case PaymentStatus.paid:
              statusStr = 'paid';
              break;
            case PaymentStatus.overdue:
              statusStr = 'overdue';
              break;
            default:
              statusStr = 'pending';
          }

          try {
            final formData = FormData.fromMap({
              if (updatedReceipt.room?.id != null)
                'roomId': updatedReceipt.room!.id,
              'date': updatedReceipt.date.toIso8601String(),
              'dueDate': updatedReceipt.dueDate.toIso8601String(),
              'lastWaterUsed': updatedReceipt.lastWaterUsed,
              'lastElectricUsed': updatedReceipt.lastElectricUsed,
              'thisWaterUsed': updatedReceipt.thisWaterUsed,
              'thisElectricUsed': updatedReceipt.thisElectricUsed,
              'paymentStatus': statusStr,
              if (updatedReceipt.services.isNotEmpty)
                'serviceIds': jsonEncode(
                    updatedReceipt.services.map((s) => s.id).toList()),
            });

            final response = await _apiHelper.dio.put(
              '${_apiHelper.baseUrl}/receipts/${updatedReceipt.id}',
              data: formData,
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
                contentType: 'multipart/form-data',
              ),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Receipt updated successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to update receipt online, will sync later: $e');
          }
        }
      }

      final index = _receiptCache.indexWhere((r) => r.id == updatedReceipt.id);
      if (index != -1) {
        if (updatedReceipt.room == null && _receiptCache[index].room != null) {
          updatedReceipt.room = _receiptCache[index].room;
        }

        if (updatedReceipt.services.isEmpty &&
            _receiptCache[index].services.isNotEmpty) {
          updatedReceipt.services =
              List<Service>.from(_receiptCache[index].services);
        }
        if (updatedReceipt.serviceIds.isEmpty &&
            _receiptCache[index].serviceIds.isNotEmpty) {
          updatedReceipt.serviceIds =
              List<String>.from(_receiptCache[index].serviceIds);
        }

        _receiptCache[index] = updatedReceipt;

        // Add to pending changes if not synced online
        if (!syncedOnline) {
          await _addPendingChange('update', {
            'id': updatedReceipt.id,
            if (updatedReceipt.room?.id != null)
              'roomId': updatedReceipt.room!.id,
            'date': updatedReceipt.date.toIso8601String(),
            'dueDate': updatedReceipt.dueDate.toIso8601String(),
            'lastWaterUsed': updatedReceipt.lastWaterUsed,
            'lastElectricUsed': updatedReceipt.lastElectricUsed,
            'thisWaterUsed': updatedReceipt.thisWaterUsed,
            'thisElectricUsed': updatedReceipt.thisElectricUsed,
            'paymentStatus':
                updatedReceipt.paymentStatus.toString().split('.').last,
            if (updatedReceipt.services.isNotEmpty)
              'serviceIds':
                  jsonEncode(updatedReceipt.services.map((s) => s.id).toList()),
          });
        }

        _hydrateReceipts();

        await save();
        _logger.i('Receipt updated in local cache');
      } else {
        throw Exception('Receipt not found: ${updatedReceipt.id}');
      }
    } catch (e) {
      _logger.e('Failed to update receipt: $e');
      throw Exception('Failed to update receipt: $e');
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    try {
      bool syncedOnline = false;

      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting receipt via API: $receiptId');

          try {
            final response = await _apiHelper.dio.delete(
              '${_apiHelper.baseUrl}/receipts/$receiptId',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
              cancelToken: _apiHelper.cancelToken,
            );

            if (response.data['cancelled'] != true &&
                response.statusCode == 200) {
              syncedOnline = true;
              _logger.i('Receipt deleted successfully via API');
            }
          } catch (e) {
            _logger.w('Failed to delete receipt online, will sync later: $e');
          }
        }
      }

      _receiptCache.removeWhere((receipt) => receipt.id == receiptId);

      // Add to pending changes if not synced online
      if (!syncedOnline) {
        await _addPendingChange('delete', {'id': receiptId});
      }

      await save();
      _logger.i('Receipt deleted from local cache');
    } catch (e) {
      _logger.e('Failed to delete receipt: $e');
      throw Exception('Failed to delete receipt: $e');
    }
  }

  Future<void> deleteLastYearReceipts() async {
    final now = DateTime.now();
    final startOfCurrentYear = DateTime(now.year, 1, 1);
    final initialLength = _receiptCache.length;
    _receiptCache
        .removeWhere((receipt) => receipt.date.isBefore(startOfCurrentYear));
    if (_receiptCache.length != initialLength) {
      await save();
    }
  }

  Future<void> restoreReceipt(int restoreIndex, Receipt receipt) async {
    if (restoreIndex >= 0 && restoreIndex <= _receiptCache.length) {
      _receiptCache.insert(restoreIndex, receipt);

      _hydrateReceipts();

      await save();
    } else {
      throw Exception('Invalid index for restoring receipt.');
    }
  }

  List<Receipt> getAllReceipts() {
    return List.unmodifiable(_receiptCache);
  }

  List<Receipt> getReceiptsForCurrentMonth() {
    final now = DateTime.now();
    return _receiptCache.where((receipt) {
      return receipt.date.year == now.year && receipt.date.month == now.month;
    }).toList();
  }

  List<Receipt> getReceiptsByMonth(int year, int month) {
    return _receiptCache.where((receipt) {
      return receipt.date.year == year && receipt.date.month == month;
    }).toList();
  }

  Future<void> updateStatusToOverdue() async {
    final now = DateTime.now();
    bool updated = false;

    for (var i = 0; i < _receiptCache.length; i++) {
      var receipt = _receiptCache[i];
      if (receipt.paymentStatus != PaymentStatus.paid &&
          receipt.dueDate.isBefore(now)) {
        _receiptCache[i] =
            receipt.copyWith(paymentStatus: PaymentStatus.overdue);
        updated = true;
      }
    }
    if (updated) await save();
  }

  List<Receipt> getReceiptsByBuilding(String buildingId) {
    return _receiptCache.where((receipt) {
      return receipt.room?.building?.id == buildingId;
    }).toList();
  }

  bool hasPendingChanges() {
    return _pendingChanges.isNotEmpty;
  }

  int getPendingChangesCount() {
    return _pendingChanges.length;
  }
}
