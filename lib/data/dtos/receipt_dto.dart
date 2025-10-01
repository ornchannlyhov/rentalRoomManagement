import 'package:receipts_v2/data/dtos/room_dto.dart';
import 'package:receipts_v2/data/dtos/service_dto.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';

class ReceiptServiceDto {
  final String id;
  final String receiptId;
  final String serviceId;
  final ServiceDto service;

  ReceiptServiceDto({
    required this.id,
    required this.receiptId,
    required this.serviceId,
    required this.service,
  });

  factory ReceiptServiceDto.fromJson(Map<String, dynamic> json) {
    return ReceiptServiceDto(
      id: json['id']?.toString() ?? '',
      receiptId: json['receiptId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      service: ServiceDto.fromJson(json['service'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptId': receiptId,
      'serviceId': serviceId,
      'service': service.toJson(),
    };
  }
}

class ReceiptDto {
  final String id;
  final DateTime date;
  final DateTime dueDate;
  final int lastWaterUsed;
  final int lastElectricUsed;
  final int thisWaterUsed;
  final int thisElectricUsed;
  final String paymentStatus;
  final String? roomId;
  final String? roomNumber;
  final RoomDto? room;
  final List<ReceiptServiceDto>? receiptServices; // Changed from services
  final String? receiptImage;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReceiptDto({
    required this.id,
    required this.date,
    required this.dueDate,
    required this.lastWaterUsed,
    required this.lastElectricUsed,
    required this.thisWaterUsed,
    required this.thisElectricUsed,
    required this.paymentStatus,
    this.roomId,
    this.roomNumber,
    this.room,
    this.receiptServices, // Changed
    this.receiptImage,
    this.source,
    this.createdAt,
    this.updatedAt,
  });

  factory ReceiptDto.fromJson(Map<String, dynamic> json) {
    return ReceiptDto(
      id: json['id']?.toString() ?? '',
      date: _parseDateTime(json['date']) ?? DateTime.now(),
      dueDate: _parseDateTime(json['dueDate']) ??
          DateTime.now().add(const Duration(days: 7)),
      lastWaterUsed: _parseInt(json['lastWaterUsed']),
      lastElectricUsed: _parseInt(json['lastElectricUsed']),
      thisWaterUsed: _parseInt(json['thisWaterUsed']),
      thisElectricUsed: _parseInt(json['thisElectricUsed']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      roomId: json['roomId']?.toString(),
      roomNumber: json['roomNumber']?.toString(),
      room: json['room'] != null
          ? RoomDto.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      receiptServices: json['receiptServices'] != null
          ? (json['receiptServices'] as List)
              .map((rs) =>
                  ReceiptServiceDto.fromJson(rs as Map<String, dynamic>))
              .toList()
          : null,
      receiptImage: json['receiptImage']?.toString(),
      source: json['source']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'lastWaterUsed': lastWaterUsed,
      'lastElectricUsed': lastElectricUsed,
      'thisWaterUsed': thisWaterUsed,
      'thisElectricUsed': thisElectricUsed,
      'paymentStatus': paymentStatus,
      if (roomId != null) 'roomId': roomId,
      if (roomNumber != null) 'roomNumber': roomNumber,
      if (room != null) 'room': room!.toJson(),
      if (receiptServices != null)
        'receiptServices': receiptServices!.map((rs) => rs.toJson()).toList(),
      if (receiptImage != null) 'receiptImage': receiptImage,
      if (source != null) 'source': source,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Receipt toReceipt() {
    PaymentStatus status;
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        status = PaymentStatus.paid;
        break;
      case 'overdue':
        status = PaymentStatus.overdue;
        break;
      default:
        status = PaymentStatus.pending;
    }

    return Receipt(
      id: id,
      date: date,
      dueDate: dueDate,
      lastWaterUsed: lastWaterUsed,
      lastElectricUsed: lastElectricUsed,
      thisWaterUsed: thisWaterUsed,
      thisElectricUsed: thisElectricUsed,
      paymentStatus: status,
      room: room?.toRoom(),
      services:
          receiptServices?.map((rs) => rs.service.toService()).toList() ?? [],
    );
  }
}
