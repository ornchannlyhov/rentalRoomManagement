import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:receipts_v2/model/enum/payment_status.dart';
import 'package:receipts_v2/model/receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptRepository {
  final String filePath = 'data/receipts.json';
  final String storageKey = 'receiptData';

  List<Receipt> _receiptCache = [];

  Future<void> _loadFromAsset() async {
    try {
      final String jsonString =
          await rootBundle.loadString('data/receipts.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _receiptCache =
          jsonData.map((receiptJson) => Receipt.fromJson(receiptJson)).toList();
    } catch (e) {
      throw Exception('Failed to load receipt data from asset: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _receiptCache = jsonData
            .map((receiptJson) => Receipt.fromJson(receiptJson))
            .toList();
      } else {
        await _loadFromAsset();
        await save();
      }
    } catch (e) {
      throw Exception('Failed to load receipt data from file: $e');
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        _receiptCache = [];
        return;
      }
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _receiptCache =
          jsonData.map((receiptJson) => Receipt.fromJson(receiptJson)).toList();
    } catch (e) {
      throw Exception('Failed to load receipt data from SharedPreferences: $e');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final file = File(filePath);
      final jsonString =
          jsonEncode(_receiptCache.map((receipt) => receipt.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save receipt data to file: $e');
    }
  }

  Future<void> _saveToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
          storageKey,
          jsonEncode(
              _receiptCache.map((receipt) => receipt.toJson()).toList()));
    } catch (e) {
      throw Exception('Failed to save receipt data to SharedPreferences: $e');
    }
  }

  Future<void> save() async {
    if (kIsWeb) {
      await _saveToSharedPreferences();
    } else {
      await _saveToFile();
      await _saveToSharedPreferences();
    }
  }

  Future<void> load() async {
    if (kIsWeb) {
      await _loadFromSharedPreferences();
    } else {
      await _loadFromFile();
    }
    if (_receiptCache.isEmpty) {
      await _loadFromAsset();
      await save();
    }
    updateReceiptStatusToOverdue();
  }
  Future<void> createReceipt(Receipt newReceipt) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final existingReceiptIndex = _receiptCache.indexWhere((receipt) {
      return receipt.room!.roomNumber == newReceipt.room!.roomNumber &&
          receipt.date
              .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          receipt.date.isBefore(endOfMonth.add(const Duration(days: 1)));
    });
    if (existingReceiptIndex != -1) {
      _receiptCache[existingReceiptIndex] = newReceipt;
    } else {
      _receiptCache.add(newReceipt);
    }
    await save();
  }

  Future<void> updateReceipt(Receipt updatedReceipt) async {
    final index =
        _receiptCache.indexWhere((receipt) => receipt.id == updatedReceipt.id);
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

  Future<void> restoreReceipt(int restoreIndex, Receipt receipt) async {
    _receiptCache.insert(restoreIndex, receipt);
    await save();
  }

  List<Receipt> getAllReceipts() {
    return List.from(_receiptCache);
  }

  List<Receipt> getReceiptsForCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _receiptCache.where((receipt) {
      return receipt.date
              .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          receipt.date.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> updateReceiptStatusToOverdue() async {
    final now = DateTime.now();
    bool isModified = false;
    for (var receipt in _receiptCache) {
      if (receipt.paymentStatus != PaymentStatus.paid &&
          receipt.dueDate.isBefore(now)) {
        receipt.paymentStatus = PaymentStatus.overdue;
        isModified = true;
      }
    }
    if (isModified) {
      await save();
    }
  }
}
