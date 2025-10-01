import 'package:receipts_v2/data/models/service.dart';

class ServiceDto {
  final String id;
  final String name;
  final double price;
  final String buildingId;
  final String? unit;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceDto({
    required this.id,
    required this.name,
    required this.price,
    required this.buildingId,
    this.unit,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) {
    return ServiceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      buildingId: json['buildingId']?.toString() ?? '',
      unit: json['unit']?.toString(),
      description: json['description']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'buildingId': buildingId,
      if (unit != null) 'unit': unit,
      if (description != null) 'description': description,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Service toService() {
    return Service(
      id: id,
      name: name,
      price: price,
      buildingId: buildingId,
    );
  }
}
