import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:receipts_v2/data/dtos/tenant_dto.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/room.dart';

class RoomDto {
  final String id;
  final String roomNumber;
  final String? buildingId;
  final BuildingDto? building;
  final TenantDto? tenant;
  final int? tenantChatId;
  final String roomStatus;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoomDto({
    required this.id,
    required this.roomNumber,
    this.buildingId,
    this.building,
    this.tenant,
    this.tenantChatId,
    required this.roomStatus,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomDto.fromJson(Map<String, dynamic> json) {
    return RoomDto(
      id: json['id']?.toString() ?? '',
      roomNumber:
          json['roomNumber']?.toString() ?? json['name']?.toString() ?? '',
      buildingId: json['buildingId']?.toString(),
      building: json['building'] != null
          ? BuildingDto.fromJson(json['building'] as Map<String, dynamic>)
          : null,
      tenant: json['tenant'] != null
          ? TenantDto.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
      tenantChatId: _parseInt(json['tenantChatId']),
      roomStatus: json['roomStatus']?.toString() ??
          json['status']?.toString() ??
          'available',
      price: _parseDouble(json['price']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
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
      'roomNumber': roomNumber,
      if (buildingId != null) 'buildingId': buildingId,
      if (building != null) 'building': building!.toJson(),
      if (tenant != null) 'tenant': tenant!.toJson(),
      if (tenantChatId != null) 'tenantChatId': tenantChatId,
      'roomStatus': roomStatus,
      'price': price,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Room toRoom() {
    RoomStatus status;
    switch (roomStatus.toLowerCase()) {
      case 'occupied':
        status = RoomStatus.occupied;
        break;
      default:
        status = RoomStatus.available;
    }

    return Room(
      id: id,
      roomNumber: roomNumber,
      roomStatus: status,
      price: price,
      building: building?.toBuilding(),
      tenant: tenant?.toTenant(),
    );
  }
}
