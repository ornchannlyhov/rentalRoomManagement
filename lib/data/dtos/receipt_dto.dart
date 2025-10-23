import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/dtos/room_dto.dart';
import 'package:receipts_v2/data/dtos/service_dto.dart';

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
      id: json['id'] as String,
      receiptId: json['receiptId'] as String,
      serviceId: json['serviceId'] as String,
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
  final List<ReceiptServiceDto>? receiptServices;
  final List<String>? serviceIds;

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
    this.receiptServices,
    this.serviceIds, 
  });

  factory ReceiptDto.fromJson(Map<String, dynamic> json) {
    List<ReceiptServiceDto>? receiptServices;
    if (json['receiptServices'] != null) {
      receiptServices = (json['receiptServices'] as List)
          .map((item) =>
              ReceiptServiceDto.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<String>? serviceIds;
    if (json['serviceIds'] != null) {
      serviceIds =
          (json['serviceIds'] as List).map((id) => id.toString()).toList();
    }

    return ReceiptDto(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      lastWaterUsed: json['lastWaterUsed'] as int,
      lastElectricUsed: json['lastElectricUsed'] as int,
      thisWaterUsed: json['thisWaterUsed'] as int,
      thisElectricUsed: json['thisElectricUsed'] as int,
      paymentStatus: json['paymentStatus'] as String,
      roomId: json['roomId'] as String?,
      roomNumber: json['roomNumber'] as String?,
      room: json['room'] != null
          ? RoomDto.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      receiptServices: receiptServices,
      serviceIds: serviceIds, 
    );
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

    final finalServiceIds =
        receiptServices?.map((rs) => rs.serviceId).toList() ?? serviceIds ?? [];

    final services =
        receiptServices?.map((rs) => rs.service.toService()).toList() ?? [];

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
      services: services, 
      serviceIds: finalServiceIds, 
    );
  }
}
