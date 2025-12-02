import 'dart:io';
import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/models/building.dart';

class BuildingDto {
  final String id;
  final String appUserId;
  final String name;
  final String? passKey;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;

  final String? buildingImage;

  final List<dynamic> services;
  final List<RoomDto>? rooms;
  final File? imageFile;

  BuildingDto({
    required this.id,
    required this.appUserId,
    required this.name,
    this.passKey,
    required this.rentPrice,
    required this.electricPrice,
    required this.waterPrice,
    this.buildingImage,
    List<dynamic>? services,
    this.rooms,
    this.imageFile,
  }) : services = services ?? [];

  factory BuildingDto.fromJson(Map<String, dynamic> json) {
    return BuildingDto(
      id: json['id']?.toString() ?? '',
      appUserId: json['appUserId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      passKey: json['passkey']?.toString(),
      rentPrice: _parseDouble(json['rentPrice']),
      electricPrice: _parseDouble(json['electricPrice']),
      waterPrice: _parseDouble(json['waterPrice']),
      buildingImage: json['buildingImage']?.toString() ??
          json['buildingImages']?.toString(),
      services: json['services'] as List? ?? [],
      rooms: json['rooms'] != null
          ? (json['rooms'] as List)
              .map((r) => RoomDto.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList()
          : null,
    );
  }

  factory BuildingDto.fromBuilding(Building building) {
    return BuildingDto(
      id: building.id,
      appUserId: building.appUserId,
      name: building.name,
      passKey: building.passKey,
      rentPrice: building.rentPrice,
      electricPrice: building.electricPrice,
      waterPrice: building.waterPrice,

      // CHANGED: Map String to String
      buildingImage: building.buildingImage,

      services: building.services,
      imageFile: building.imageFile,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appUserId': appUserId,
      'name': name,
      if (passKey != null) 'passkey': passKey,
      'rentPrice': rentPrice,
      'electricPrice': electricPrice,
      'waterPrice': waterPrice,

      // CHANGED: Sending string
      'buildingImage': buildingImage,

      'services': services,
      if (rooms != null) 'rooms': rooms!.map((r) => r.toJson()).toList(),
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'rentPrice': rentPrice,
      'electricPrice': electricPrice,
      'waterPrice': waterPrice,
      // You might want to include buildingImage here too if it's part of the update request
      if (buildingImage != null) 'buildingImage': buildingImage,
    };
  }

  Building toBuilding() {
    return Building(
      id: id,
      appUserId: appUserId,
      name: name,
      rentPrice: rentPrice,
      electricPrice: electricPrice,
      waterPrice: waterPrice,
      passKey: passKey,

      // CHANGED: Map String to String
      buildingImage: buildingImage,

      services: services,
      rooms: rooms?.map((r) => r.toRoom()).toList() ?? [],
      imageFile: imageFile,
    );
  }
}
