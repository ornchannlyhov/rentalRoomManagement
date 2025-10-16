import 'package:receipts_v2/data/models/room.dart';

class Building {
  final String id;
  final String name;
  List<Room> rooms;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;

  Building({
    required this.id,
    required this.name,
    required this.rentPrice,
    List<Room>? rooms,
    required this.electricPrice,
    required this.waterPrice,
  }) : rooms = rooms ?? [];
}
