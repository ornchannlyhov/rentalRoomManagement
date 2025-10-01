import 'package:receipts_v2/data/dtos/room_dto.dart';
import 'package:receipts_v2/data/models/building.dart';

class BuildingDto {
  final String id;
  final String name;
  final double rentPrice;
  final double electricPrice;
  final double waterPrice;
  final String? passkey;
  final List<RoomDto>? rooms;

  BuildingDto({
    required this.id,
    required this.name,
    required this.rentPrice,
    required this.electricPrice,
    required this.waterPrice,
    this.passkey,
    this.rooms,
  });

  factory BuildingDto.fromJson(Map<String, dynamic> json) {
    return BuildingDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rentPrice: _parseDouble(json['rentPrice']),
      electricPrice: _parseDouble(json['electricPrice']),
      waterPrice: _parseDouble(json['waterPrice']),
      passkey: json['passkey']?.toString(),
      rooms: json['rooms'] != null
          ? (json['rooms'] as List)
              .map((r) => RoomDto.fromJson(r as Map<String, dynamic>))
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
      'name': name,
      'rentPrice': rentPrice,
      'electricPrice': electricPrice,
      'waterPrice': waterPrice,
      if (passkey != null) 'passkey': passkey,
      if (rooms != null) 'rooms': rooms!.map((r) => r.toJson()).toList(),
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
