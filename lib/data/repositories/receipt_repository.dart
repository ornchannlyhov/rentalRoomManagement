import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

class ReceiptRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'receipt_secure_data';
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  List<Receipt> _receiptCache = [];

  Future<void> load() async {
    try {
      _logger.i('Loading receipts from secure storage');
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _receiptCache = jsonData.map((json) {
          final receiptDto = ReceiptDto.fromJson(json);
          final receipt = receiptDto.toReceipt();

          if (receiptDto.room != null) {
            receipt.room = receiptDto.room!.toRoom();
            if (receiptDto.room!.building != null) {
              receipt.room!.building = receiptDto.room!.building!.toBuilding();
            }
          }

          if (receiptDto.receiptServices != null) {
            receipt.services = receiptDto.receiptServices!
                .map((rs) => rs.service.toService())
                .toList();
          }

          return receipt;
        }).toList();
        _logger.i('Loaded ${_receiptCache.length} receipts from storage');
      } else {
        _receiptCache = [];
      }
    } catch (e) {
      _logger.e('Error loading receipts from secure storage: $e');
      _receiptCache = [];
    }

    await updateStatusToOverdue();
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
      _logger.d('Saved ${_receiptCache.length} receipts to storage');
    } catch (e) {
      _logger.e('Failed to save receipts to secure storage: $e');
      throw Exception('Failed to save receipts to secure storage: $e');
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

          // Reconstruct room and building references
          if (receiptDto.room != null) {
            receipt.room = receiptDto.room!.toRoom();
            if (receiptDto.room!.building != null) {
              receipt.room!.building = receiptDto.room!.building!.toBuilding();
            }
          }

          // Services are already set in toReceipt() from receiptServices
          // But ensure serviceIds is also populated
          if (receiptDto.receiptServices != null &&
              receiptDto.receiptServices!.isNotEmpty) {
            receipt.services = receiptDto.receiptServices!
                .map((rs) => rs.service.toService())
                .toList();
            receipt.serviceIds =
                receiptDto.receiptServices!.map((rs) => rs.serviceId).toList();
          } else {
            receipt.services = [];
            receipt.serviceIds = [];
          }

          return receipt;
        }).toList();

        if (!skipHydration) {
          await save();
        }
        _logger.i('Synced ${_receiptCache.length} receipts from API');
      }
    } catch (e) {
      _logger.e('Failed to sync receipts from API: $e');
    }
  }

  Future<void> createReceipt(Receipt newReceipt) async {
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

          final formData = FormData.fromMap({
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
          });

          final response = await _apiHelper.dio.post(
            '${_apiHelper.baseUrl}/receipts',
            data: formData,
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
              contentType: 'multipart/form-data',
            ),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] == true) {
            _logger.w('Request cancelled, saving locally');
            if (existingIndex != -1) {
              _receiptCache[existingIndex] = newReceipt;
            } else {
              _receiptCache.add(newReceipt);
            }
            await save();
            return;
          }

          if (response.statusCode == 201 && response.data['success'] == true) {
            final receiptDto = ReceiptDto.fromJson(response.data['data']);
            createdReceipt = receiptDto.toReceipt();

            // Preserve room and building references from newReceipt
            createdReceipt.room = newReceipt.room;

            // Preserve services and serviceIds from newReceipt
            // API might not return full service objects, so use local data
            createdReceipt.services = List<Service>.from(newReceipt.services);
            createdReceipt.serviceIds =
                List<String>.from(newReceipt.serviceIds);

            if (existingIndex != -1) {
              _receiptCache[existingIndex] = createdReceipt;
            } else {
              _receiptCache.add(createdReceipt);
            }
            _logger.i('Receipt created successfully via API');
          } else {
            throw Exception(
                'Failed to create receipt via API: ${response.statusCode}');
          }
        } else {
          if (existingIndex != -1) {
            _receiptCache[existingIndex] = newReceipt;
          } else {
            _receiptCache.add(newReceipt);
          }
        }
      } else {
        if (existingIndex != -1) {
          _receiptCache[existingIndex] = newReceipt;
        } else {
          _receiptCache.add(newReceipt);
        }
      }

      await save();
    } catch (e) {
      _logger.e('Failed to create receipt: $e');
      throw Exception('Failed to create receipt: $e');
    }
  }

  Future<void> updateReceipt(Receipt updatedReceipt) async {
    try {
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
              'serviceIds':
                  jsonEncode(updatedReceipt.services.map((s) => s.id).toList()),
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
              response.statusCode != 200) {
            throw Exception('Failed to update receipt via API');
          }
        }
      }

      final index = _receiptCache.indexWhere((r) => r.id == updatedReceipt.id);
      if (index != -1) {
        // Preserve room reference if not provided
        if (updatedReceipt.room == null && _receiptCache[index].room != null) {
          updatedReceipt.room = _receiptCache[index].room;
        }

        // Preserve services and serviceIds if not provided
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
        await save();
        _logger.i('Receipt updated successfully');
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
      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          _logger.i('Deleting receipt via API: $receiptId');

          final response = await _apiHelper.dio.delete(
            '${_apiHelper.baseUrl}/receipts/$receiptId',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            cancelToken: _apiHelper.cancelToken,
          );

          if (response.data['cancelled'] != true &&
              response.statusCode != 200) {
            throw Exception('Failed to delete receipt via API');
          }
        }
      }

      _receiptCache.removeWhere((receipt) => receipt.id == receiptId);
      await save();
      _logger.i('Receipt deleted successfully');
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

  Future<String?> getReceiptImageUrl(String receiptId) async {
    try {
      if (await _apiHelper.hasNetwork()) {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null) {
          return '${_apiHelper.baseUrl}/receipts/$receiptId/image';
        }
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get receipt image URL: $e');
      return null;
    }
  }

}
