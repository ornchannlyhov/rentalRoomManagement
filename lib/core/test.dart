import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/gender.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:uuid/uuid.dart';

void main() {
  Building building = Building(
      id: const Uuid().v4(),
      name: 'Building A',
      rentPrice: 100.0,
      electricPrice: 0.3,
      waterPrice: 0.5);
  Room room1 = Room(
      id: const Uuid().v4(),
      roomNumber: 'A102',
      roomStatus: RoomStatus.available,
      price: 120);
  room1.building = building;
  Tenant tenant = Tenant(
      id: const Uuid().v4(),
      name: 'ly hov',
      phoneNumber: '096 414 1037',
      gender: Gender.male);
  tenant.room = room1;
  Service service1 =
      Service(id: const Uuid().v4(), name: 'Internet', price: 5.0,  buildingId: '');
  Service service2 =
      Service(id: const Uuid().v4(), name: 'cleaning', price: 2.0,  buildingId: '');
  Receipt receipt = Receipt(
      id: const Uuid().v4(),
      date: DateTime.now(),
      dueDate: DateTime.now(),
      lastWaterUsed: 10,
      lastElectricUsed: 26,
      thisWaterUsed: 15,
      thisElectricUsed: 36,
      paymentStatus: PaymentStatus.pending,
      services: [service2, service1]);

  receipt.room = room1;
  debugPrint(receipt.electricPrice.toString());
  debugPrint(receipt.waterPrice.toString());
  debugPrint(receipt.totalServicePrice.toString());
  debugPrint(receipt.totalPrice.toString());
}
