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
  final List<String> buildingImages;
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
    List<String>? buildingImages,
    List<dynamic>? services,
    this.rooms,
    this.imageFile, 
  })  : buildingImages = buildingImages ?? [],
        services = services ?? [];

  factory BuildingDto.fromJson(Map<String, dynamic> json) {
    return BuildingDto(
      id: json['id']?.toString() ?? '',
      appUserId: json['appUserId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      passKey: json['passkey']?.toString(),
      rentPrice: _parseDouble(json['rentPrice']),
      electricPrice: _parseDouble(json['electricPrice']),
      waterPrice: _parseDouble(json['waterPrice']),
      buildingImages: json['buildingImages'] != null
          ? (json['buildingImages'] as List).map((e) => e.toString()).toList()
          : [],
      services: json['services'] as List? ?? [],
      rooms: json['rooms'] != null
          ? (json['rooms'] as List)
              .map((r) => RoomDto.fromJson(r as Map<String, dynamic>))
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
      buildingImages: building.buildingImages,
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
      'buildingImages': buildingImages,
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
      buildingImages: buildingImages,
      services: services,
      rooms: rooms?.map((r) => r.toRoom()).toList() ?? [],
      imageFile: imageFile, 
    );
  }
}
