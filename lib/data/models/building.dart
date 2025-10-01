import 'package:receipts_v2/data/models/room.dart';

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
}
