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

          // Preserve full room and building references
          if (receiptDto.room != null) {
            receipt.room = receiptDto.room!.toRoom();
            if (receiptDto.room!.building != null) {
              receipt.room!.building = receiptDto.room!.building!.toBuilding();
            }
          }

          // Preserve services
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

          // Save with full room and building data
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

  Future<void> syncFromApi({bool skipHydration = false}) async {
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
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/flutter-receipts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        cancelToken: _apiHelper.cancelToken,
      );

      if (response.data['cancelled'] == true) {
        _logger.w('Request cancelled due to network loss');
        return;
      }

      if (response.statusCode == 200) {
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

          // Reconstruct service references
          if (receiptDto.receiptServices != null) {
            receipt.services = receiptDto.receiptServices!
                .map((rs) => rs.service.toService())
                .toList();
          } else {
            receipt.services = [];
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
      // Validate required references
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

      Receipt createdReceipt =
          newReceipt; // Default to input receipt for offline case

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
            'roomNumber': newReceipt.room!.roomNumber,
            'date': newReceipt.date.toIso8601String(),
            'dueDate': newReceipt.dueDate.toIso8601String(),
            'lastWaterUsed': newReceipt.lastWaterUsed,
            'lastElectricUsed': newReceipt.lastElectricUsed,
            'thisWaterUsed': newReceipt.thisWaterUsed,
            'thisElectricUsed': newReceipt.thisElectricUsed,
            'paymentStatus': statusStr,
            'services': newReceipt.services
                .map((service) => {
                      'id': service.id,
                      'name': service.name,
                      'price': service.price,
                      'buildingId': service.buildingId,
                    })
                .toList(),
          });

          final response = await _apiHelper.dio.post(
            '${_apiHelper.baseUrl}/flutter-receipts',
            data: formData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
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

          if (response.statusCode == 201) {
            final receiptDto = ReceiptDto.fromJson(response.data['data']);
            createdReceipt = receiptDto.toReceipt();

            // Preserve room, building, and service references from newReceipt
            createdReceipt.room = newReceipt.room;
            createdReceipt.services = List<Service>.from(newReceipt.services);

            if (existingIndex != -1) {
              _receiptCache[existingIndex] = createdReceipt;
            } else {
              _receiptCache.add(createdReceipt);
            }
            _logger.i('Receipt created successfully via API');
          }
        } else {
          // No token, proceed with local creation
          if (existingIndex != -1) {
            _receiptCache[existingIndex] = newReceipt;
          } else {
            _receiptCache.add(newReceipt);
          }
        }
      } else {
        // No network, proceed with local creation
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
            if (updatedReceipt.room?.roomNumber != null)
              'roomNumber': updatedReceipt.room!.roomNumber,
            'date': updatedReceipt.date.toIso8601String(),
            'dueDate': updatedReceipt.dueDate.toIso8601String(),
            'lastWaterUsed': updatedReceipt.lastWaterUsed,
            'lastElectricUsed': updatedReceipt.lastElectricUsed,
            'thisWaterUsed': updatedReceipt.thisWaterUsed,
            'thisElectricUsed': updatedReceipt.thisElectricUsed,
            'paymentStatus': statusStr,
            'services': updatedReceipt.services
                .map((service) => {
                      'id': service.id,
                      'name': service.name,
                      'price': service.price,
                      'buildingId': service.buildingId,
                    })
                .toList(),
          });

          final response = await _apiHelper.dio.put(
            '${_apiHelper.baseUrl}/flutter-receipts/${updatedReceipt.id}',
            data: formData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
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
        // Preserve room and services references if not provided
        if (updatedReceipt.room == null && _receiptCache[index].room != null) {
          updatedReceipt.room = _receiptCache[index].room;
        }
        if (updatedReceipt.services.isEmpty &&
            _receiptCache[index].services.isNotEmpty) {
          updatedReceipt.services =
              List<Service>.from(_receiptCache[index].services);
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
            '${_apiHelper.baseUrl}/flutter-receipts/$receiptId',
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
}
