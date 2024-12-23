import 'package:receipts_v2/model/enum/payment_status.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/model/service.dart';
import 'package:json_annotation/json_annotation.dart';

part 'JsonSerializable/receipt.g.dart';

@JsonSerializable(explicitToJson: true)
class Receipt {
  final String id;
  final DateTime date;
  final DateTime dueDate;
  int lastWaterUsed;
  int lastElectricUsed;
  final int thisWaterUsed;
  final int thisElectricUsed;
  PaymentStatus paymentStatus;
  List<Service> services;
  Room? room;

  Receipt({
    required this.id,
    required this.date,
    required this.dueDate,
    required this.lastWaterUsed,
    required this.lastElectricUsed,
    required this.thisWaterUsed,
    required this.thisElectricUsed,
    required this.paymentStatus,
    this.room,
    this.services = const [],
  });

  double calculateWaterPrice() {
    if (room == null) {
      throw Exception("Room must be set before calculating water price.");
    }
    return (thisWaterUsed - lastWaterUsed) * room!.building!.waterPrice;
  }

  double calculateElectricPrice() {
    if (room == null) {
      throw Exception("Room must be set before calculating electric price.");
    }
    return (thisElectricUsed - lastElectricUsed) *
        room!.building!.electricPrice;
  }

  double calculateTotalServicePrice() =>
      services.fold(0.0, (total, service) => total + service.price);

  double calculateTotalPrice() =>
      calculateWaterPrice() +
      calculateElectricPrice() +
      calculateTotalServicePrice() +
      room!.price;

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);

  Map<String, dynamic> toJson() => _$ReceiptToJson(this);
}
