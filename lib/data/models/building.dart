import 'package:joul_v2/data/models/room.dart';

class Building {
  final String id;
  final String appUserId;
  final String name;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;
  final String? passKey;
  final List<String> buildingImages;
  final List<dynamic> services;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<Room> rooms;

  Building({
    required this.id,
    required this.appUserId,
    required this.name,
    required this.rentPrice,
    required this.electricPrice,
    required this.waterPrice,
    String? passKey,
    List<String>? buildingImages,
    List<dynamic>? services,
    required this.createdAt,
    required this.updatedAt,
    List<Room>? rooms,
  })  : passKey = passKey,
        buildingImages = buildingImages ?? [],
        services = services ?? [],
        rooms = rooms ?? [];
}
