import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';

class ReceiptRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'receipt_secure_data';

  List<Receipt> _receiptCache = [];

  Future<void> load() async {
    try {
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _receiptCache = jsonData.map((json) => Receipt.fromJson(json)).toList();
      } else {
        _receiptCache = [];
      }
    } catch (e) {
      print('Error loading receipts from secure storage: $e');
      _receiptCache = []; 
    }

    await updateStatusToOverdue();
  }

  Future<void> save() async {
    try {
      final jsonString = jsonEncode(
        _receiptCache.map((receipt) => receipt.toJson()).toList(),
      );
      await _secureStorage.write(key: storageKey, value: jsonString);
    } catch (e) {
      print('Failed to save receipts to secure storage: $e');
      throw Exception('Failed to save receipts to secure storage: $e');
    }
  }

  Future<void> createReceipt(Receipt newReceipt) async {
    final existingIndex = _receiptCache.indexWhere((receipt) {
      return receipt.room?.roomNumber == newReceipt.room?.roomNumber &&
          receipt.date.year == newReceipt.date.year &&
          receipt.date.month == newReceipt.date.month;
    });

    if (existingIndex != -1) {
      _receiptCache[existingIndex] = newReceipt;
    } else {
      _receiptCache.add(newReceipt);
    }

    await save();
  }

  Future<void> updateReceipt(Receipt updatedReceipt) async {
    final index = _receiptCache.indexWhere((r) => r.id == updatedReceipt.id);
    if (index != -1) {
      _receiptCache[index] = updatedReceipt;
      await save();
    } else {
      throw Exception('Receipt not found: ${updatedReceipt.id}');
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    _receiptCache.removeWhere((receipt) => receipt.id == receiptId);
    await save();
  }

  Future<void> deleteLastYearReceipts() async {
    final now = DateTime.now();
    final startOfCurrentYear = DateTime(now.year, 1, 1);
    final initialLength = _receiptCache.length;
    _receiptCache.removeWhere((receipt) => receipt.date.isBefore(startOfCurrentYear));
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
        _receiptCache[i] = receipt.copyWith(paymentStatus: PaymentStatus.overdue);
        updated = true;
      }
    }

    if (updated) await save();
  }
}