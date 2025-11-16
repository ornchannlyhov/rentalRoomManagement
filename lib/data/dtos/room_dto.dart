import 'package:joul_v2/data/dtos/building_dto.dart';
import 'package:joul_v2/data/dtos/tenant_dto.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/data/models/room.dart';

class RoomDto {
  final String id;
  final String roomNumber;
  final String? buildingId;
  final String roomStatus;
  final double price;
  final BuildingDto? building;
  final TenantDto? tenant;
  final List<dynamic>? receipts;
  final List<dynamic>? reports;

  RoomDto({
    required this.id,
    required this.roomNumber,
    this.buildingId,
    required this.roomStatus,
    required this.price,
    this.building,
    this.tenant,
    this.receipts,
    this.reports,
  });

  factory RoomDto.fromJson(Map<String, dynamic> json) {
    return RoomDto(
      id: json['id']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      buildingId: json['buildingId']?.toString(),
      roomStatus: json['roomStatus']?.toString() ?? 'available',
      price: _parseDouble(json['price']),
      building: json['building'] != null
          ? BuildingDto.fromJson(json['building'] as Map<String, dynamic>)
          : null,
      tenant: json['tenant'] != null
          ? TenantDto.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
      receipts: json['receipts'] as List?,
      reports: json['reports'] as List?,
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
      'roomNumber': roomNumber,
      if (buildingId != null) 'buildingId': buildingId,
      'roomStatus': roomStatus,
      'price': price,
      if (building != null) 'building': building!.toJson(),
      if (tenant != null) 'tenant': tenant!.toJson(),
      if (receipts != null) 'receipts': receipts,
      if (reports != null) 'reports': reports,
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'buildingId': buildingId,
      'roomNumber': roomNumber,
      'price': price,
      'roomStatus': roomStatus,
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

    final room = Room(
      id: id,
      roomNumber: roomNumber,
      roomStatus: status,
      price: price,
    );

    if (building != null) {
      room.building = building!.toBuilding();
    } else if (buildingId != null && buildingId!.isNotEmpty) {
      // FIXED: Updated to match new Building constructor with required fields
      room.building = Building(
        id: buildingId!,
        appUserId: '', // Placeholder - will be populated when full building data is loaded
        name: '',
        rentPrice: 0.0,
        electricPrice: 0.0,
        waterPrice: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rooms: [],
      );
    }

    if (tenant != null) {
      room.tenant = tenant!.toTenant();
      if (room.tenant != null) {
        room.tenant!.room = room;
      }
    }

    return room;
  }
}