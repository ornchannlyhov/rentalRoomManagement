import 'dart:io';
import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';

class TenantDto {
  final String id;
  final String name;
  final String phoneNumber;
  final String gender;
  final String? chatId;
  final String language;
  final double deposit;
  final String? tenantProfile;
  final String? roomId;
  final RoomDto? room;
  final File? imageFile;

  TenantDto({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    this.chatId,
    required this.language,
    required this.deposit,
    this.tenantProfile,
    this.roomId,
    this.room,
    this.imageFile,
  });

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    return TenantDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'other',
      chatId: json['chatId']?.toString(),
      language: json['language']?.toString() ?? 'english',
      deposit: _parseDouble(json['deposit']),
      tenantProfile: json['tenantProfile']?.toString(),
      roomId: json['roomId']?.toString(),
      room: json['room'] != null
          ? RoomDto.fromJson(Map<String, dynamic>.from(json['room'] as Map))
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
      'phoneNumber': phoneNumber,
      'gender': gender,
      'chatId': chatId,
      'language': language,
      'deposit': deposit,
      'tenantProfile': tenantProfile,
      'roomId': roomId,
      if (room != null) 'room': room!.toJson(),
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

    final tenant = Tenant(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      gender: genderEnum,
      chatId: chatId,
      language: language,
      deposit: deposit,
      tenantProfile: tenantProfile,
      room: room?.toRoom(),
      imageFile: imageFile,
    );

    if (tenant.room == null && roomId != null && roomId!.isNotEmpty) {
      // Create placeholder Room with ID
      tenant.room = Room(
        id: roomId!,
        roomNumber: '',
        roomStatus: RoomStatus.available,
        price: 0.0,
      );
    }

    return tenant;
  }
}
