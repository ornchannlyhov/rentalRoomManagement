import 'package:receipts_v2/model/building.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:receipts_v2/model/client.dart';
import 'package:receipts_v2/model/enum/room_status.dart';

part 'JsonSerializable/room.g.dart';

@JsonSerializable(explicitToJson: true)
class Room {
  final String id;
  final String roomNumber;
  Building? building;
  Client? client;
  RoomStatus roomStatus;
  double price;

  Room(
      {required this.id,
      required this.roomNumber,
      required this.roomStatus,
      required this.price,
      this.building,
      this.client});

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
