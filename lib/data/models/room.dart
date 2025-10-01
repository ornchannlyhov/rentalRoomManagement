import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';

class Room {
  final String id;
  final String roomNumber;
  final String buildingId;
  Building? building;
  Tenant? tenant;
  RoomStatus roomStatus;
  double price;

  Room({
    required this.id,
    required this.roomNumber,
    required this.roomStatus,
    required this.price,
    required this.buildingId,
    this.building,
    this.tenant,
  });

}
