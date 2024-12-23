import 'package:receipts_v2/model/room.dart';
import 'package:json_annotation/json_annotation.dart';

part 'JsonSerializable/building.g.dart';

@JsonSerializable(explicitToJson: true)
class Building {
  final String id;
  final String name;
  final List<Room> rooms;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;

  Building(
      {required this.id,
      required this.name,
      required this.rentPrice,
      this.rooms = const [],
      required this.electricPrice,
      required this.waterPrice});

  factory Building.fromJson(Map<String, dynamic> json) =>
      _$BuildingFromJson(json);

  Map<String, dynamic> toJson() => _$BuildingToJson(this);
}
