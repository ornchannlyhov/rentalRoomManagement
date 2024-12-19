import 'package:receipts_v2/model/building.dart';
import 'package:receipts_v2/model/client.dart';
import 'package:receipts_v2/model/enum/gender.dart';
import 'package:receipts_v2/model/enum/payment_status.dart';
import 'package:receipts_v2/model/enum/room_status.dart';
import 'package:receipts_v2/model/receipt.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/model/service.dart';
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
      roomStatus: RoomStatus.available, price: 120);
  room1.building = building;
  Client client = Client(
      id: const Uuid().v4(), name: 'ly hov', phoneNumber: '096 414 1037',gender: Gender.male);
  client.room=room1;
  Service service1 =
      Service(id: const Uuid().v4(), name: 'Internet', price: 5.0);
  Service service2 =
      Service(id: const Uuid().v4(), name: 'cleaning', price: 2.0);
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
  print(receipt.calculateElectricPrice());
  print(receipt.calculateWaterPrice());
  print(receipt.calculateTotalServicePrice());
  print(receipt.calculateTotalPrice());
}
