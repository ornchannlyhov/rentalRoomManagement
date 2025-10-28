import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/models/tenant.dart';

class TenantDto {
  final String id;
  final String name;
  final String phoneNumber;
  final String gender;
  final String? roomId;
  final RoomDto? room;

  TenantDto({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    this.roomId,
    this.room,
  });

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    return TenantDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'other',
      roomId: json['roomId']?.toString(),
      room: json['room'] != null
          ? RoomDto.fromJson(json['room'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'gender': gender,
      if (roomId != null) 'roomId': roomId,
      if (room != null) 'room': room!.toJson(),
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'gender': gender,
      if (roomId != null) 'roomId': roomId,
    };
  }

  Tenant toTenant() {
    Gender genderEnum;
    switch (gender.toLowerCase()) {
      case 'male':
        genderEnum = Gender.male;
        break;
      case 'female':
        genderEnum = Gender.female;
        break;
      default:
        genderEnum = Gender.other;
    }

    return Tenant(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      gender: genderEnum,
      room: room?.toRoom(),
    );
  }
}