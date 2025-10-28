import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/dtos/service_dto.dart';
import 'package:joul_v2/data/models/building.dart';

class BuildingDto {
  final String id;
  final String? appUserId;
  final String name;
  final String? passkey;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;
  final List<RoomDto>? rooms;
  final List<ServiceDto>? services;

  BuildingDto({
    required this.id,
    this.appUserId,
    required this.name,
    this.passkey,
    required this.rentPrice,
    required this.electricPrice,
    required this.waterPrice,
    this.rooms,
    this.services,
  });

  factory BuildingDto.fromJson(Map<String, dynamic> json) {
    return BuildingDto(
      id: json['id']?.toString() ?? '',
      appUserId: json['appUserId']?.toString(),
      name: json['name']?.toString() ?? '',
      passkey: json['passkey']?.toString(),
      rentPrice: _parseDouble(json['rentPrice']),
      electricPrice: _parseDouble(json['electricPrice']),
      waterPrice: _parseDouble(json['waterPrice']),
      rooms: json['rooms'] != null
          ? (json['rooms'] as List)
              .map((r) => RoomDto.fromJson(r as Map<String, dynamic>))
              .toList()
          : null,
      services: json['services'] != null
          ? (json['services'] as List)
              .map((s) => ServiceDto.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
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
      if (appUserId != null) 'appUserId': appUserId,
      'name': name,
      if (passkey != null) 'passkey': passkey,
      'rentPrice': rentPrice,
      'electricPrice': electricPrice,
      'waterPrice': waterPrice,
      if (rooms != null) 'rooms': rooms!.map((r) => r.toJson()).toList(),
      if (services != null)
        'services': services!.map((s) => s.toJson()).toList(),
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
      name: name,
      rentPrice: rentPrice,
      electricPrice: electricPrice,
      waterPrice: waterPrice,
      rooms: rooms?.map((r) => r.toRoom()).toList() ?? [],
    );
  }
}