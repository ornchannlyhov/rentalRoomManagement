
import 'package:joul_v2/data/models/service.dart';

class ServiceDto {
  final String id;
  final String name;
  final double price;
  final String buildingId;

  ServiceDto({
    required this.id,
    required this.name,
    required this.price,
    required this.buildingId,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) {
    return ServiceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      buildingId: json['buildingId']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'buildingId': buildingId,
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'buildingId': buildingId,
      'name': name,
      'price': price,
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
