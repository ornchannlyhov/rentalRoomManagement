import 'package:joul_v2/data/models/room.dart';

class Building {
  final String id;
  final String name;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;
  final String? passKey;
  List<Room> rooms;

  Building({
    required this.id,
    required this.name,
    required this.rentPrice,
    required this.electricPrice,
    required this.waterPrice,
    String? passKey,
    List<Room>? rooms,
  })  : passKey = passKey,
        rooms = rooms ?? [];
}
