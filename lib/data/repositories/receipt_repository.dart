import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/core/api_helper.dart';
import 'package:receipts_v2/data/dtos/receipt_dto.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';

class ReceiptRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();
  final AuthRepository _authRepository;

  List<Receipt> _receiptCache = [];

  ReceiptRepository(this._authRepository);

  Future<bool> _hasNetwork() => _apiHelper.hasNetwork();

  Future<String?> _getToken() async {
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }
    return token;
  }

  Future<List<ReceiptDto>> _fetchReceiptDtos() async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/flutter-receipts';

    try {
      final response = await _apiHelper.dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((json) => ReceiptDto.fromJson(json)).toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to fetch receipts: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      _logger.e('fetchReceiptDtos error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to fetch receipts';
      throw Exception(errorMessage);
    }
  }

  Future<void> load() async {
    try {
      final dtos = await _fetchReceiptDtos();
      _receiptCache = dtos.map((dto) => dto.toReceipt()).toList();
      await updateStatusToOverdue();
      _logger
          .i('Receipts loaded successfully: ${_receiptCache.length} receipts');
    } catch (e) {
      _logger.e('Failed to load receipts: $e');
      if (_receiptCache.isEmpty) {
        throw Exception('Failed to load receipt data: $e');
      }
      rethrow;
    }
  }

  Future<Receipt> createReceipt(Receipt newReceipt) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/flutter-receipts';

    try {
      // API expects multipart/form-data
      final formData = FormData.fromMap({
        'roomId': newReceipt.room!.id,
        'roomNumber': newReceipt.room!.roomNumber,
        'date': newReceipt.date.toIso8601String(),
        'dueDate': newReceipt.dueDate.toIso8601String(),
        'lastWaterUsed': newReceipt.lastWaterUsed,
        'lastElectricUsed': newReceipt.lastElectricUsed,
        'thisWaterUsed': newReceipt.thisWaterUsed,
        'thisElectricUsed': newReceipt.thisElectricUsed,
        'paymentStatus': newReceipt.paymentStatus.name,
        // Add receiptImage if available
        // 'receiptImage': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiHelper.dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final receiptDto =
            ReceiptDto.fromJson(response.data['data'] ?? response.data);
        final createdReceipt = receiptDto.toReceipt();
        _receiptCache.add(createdReceipt);
        _logger.i('Receipt created successfully');
        return createdReceipt;
      } else {
        throw Exception('Failed to create receipt: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Invalid roomId';
        throw Exception(errorMessage);
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Room not found or not authorized');
      }
      _logger.e('createReceipt error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to create receipt';
      throw Exception(errorMessage);
    }
  }

  Future<Receipt> updateReceipt(Receipt updatedReceipt) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/flutter-receipts/${updatedReceipt.id}';

    try {
      // API expects multipart/form-data
      final formData = FormData.fromMap({
        if (updatedReceipt.room != null) 'roomId': updatedReceipt.room!.id,
        if (updatedReceipt.room != null)
          'roomNumber': updatedReceipt.room!.roomNumber,
        'date': updatedReceipt.date.toIso8601String(),
        'dueDate': updatedReceipt.dueDate.toIso8601String(),
        'lastWaterUsed': updatedReceipt.lastWaterUsed,
        'lastElectricUsed': updatedReceipt.lastElectricUsed,
        'thisWaterUsed': updatedReceipt.thisWaterUsed,
        'thisElectricUsed': updatedReceipt.thisElectricUsed,
        'paymentStatus': updatedReceipt.paymentStatus.name,
        // Add receiptImage if available
        // 'receiptImage': await MultipartFile.fromFile(imagePath),
      });

      final response = await _apiHelper.dio.put(
        url,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        final receiptDto =
            ReceiptDto.fromJson(response.data['data'] ?? response.data);
        final updated = receiptDto.toReceipt();
        final index =
            _receiptCache.indexWhere((r) => r.id == updatedReceipt.id);
        if (index != -1) {
          _receiptCache[index] = updated;
        }
        _logger.i('Receipt updated successfully');
        return updated;
      } else {
        throw Exception('Failed to update receipt: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Receipt not found or not authorized');
      }
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Invalid roomId';
        throw Exception(errorMessage);
      }
      _logger.e('updateReceipt error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to update receipt';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/flutter-receipts/$receiptId';

    try {
      final response = await _apiHelper.dio.delete(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _receiptCache.removeWhere((r) => r.id == receiptId);
        _logger.i('Receipt deleted successfully');
      } else {
        throw Exception('Failed to delete receipt: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Receipt not found or not authorized');
      }
      _logger.e('deleteReceipt error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to delete receipt';
      throw Exception(errorMessage);
    }
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

    if (updated) {
      _logger.i('Updated overdue receipts locally');
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

  List<Receipt> getReceiptsByBuilding(String buildingId) {
    return _receiptCache.where((receipt) {
      return receipt.room?.building?.id == buildingId;
    }).toList();
  }

  Receipt? getReceiptById(String receiptId) {
    try {
      return _receiptCache.firstWhere((r) => r.id == receiptId);
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _receiptCache.clear();
    _logger.i('Receipt cache cleared');
  }

  bool hasData() {
    return _receiptCache.isNotEmpty;
  }
}
