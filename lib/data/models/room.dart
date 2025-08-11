import 'package:json_annotation/json_annotation.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';

part '../dtos/room.g.dart'; 

@JsonSerializable(explicitToJson: true)
class Room {
  final String id;
  final String roomNumber;
  Building? building;
  Tenant? tenant;
  RoomStatus roomStatus;
  double price;

  Room({
    required this.id,
    required this.roomNumber,
    required this.roomStatus,
    required this.price,
    this.building,
    this.tenant,
  });

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
