import 'dart:io';
import 'package:joul_v2/data/models/room.dart';

class Building {
  final String id;
  final String appUserId;
  final String name;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;
  final String? passKey;

  final String? buildingImage;

  final List<dynamic> services;
  List<Room> rooms;
  File? imageFile;

  Building({
    required this.id,
    required this.appUserId,
    required this.name,
    required this.rentPrice,
    required this.electricPrice,
    required this.waterPrice,
    this.passKey,
    this.buildingImage, 
    List<dynamic>? services,
    List<Room>? rooms,
    this.imageFile,
  })  : services = services ?? [],
        rooms = rooms ?? [];
}
