import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/dtos/service_dto.dart';
import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/data/models/receipt.dart';

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
  final List<ServiceDto>? services;
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
    this.services,
    this.serviceIds,
  });

  factory ReceiptDto.fromJson(Map<String, dynamic> json) {
    List<ServiceDto>? services;
    if (json['services'] != null) {
      services = (json['services'] as List)
          .map((item) =>
              ServiceDto.fromJson(Map<String, dynamic>.from(item as Map)))
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
          ? RoomDto.fromJson(Map<String, dynamic>.from(json['room'] as Map))
          : null,
      services: services,
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
      if (services != null)
        'services': services!.map((s) => s.toJson()).toList(),
      if (serviceIds != null) 'serviceIds': serviceIds,
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
        services?.map((s) => s.id).toList() ?? serviceIds ?? [];

    final serviceObjects = services?.map((s) => s.toService()).toList() ?? [];

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
      services: serviceObjects,
      serviceIds: finalServiceIds,
    );
  }
}
