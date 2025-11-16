import 'package:joul_v2/data/dtos/room_dto.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/models/tenant.dart';

class TenantDto {
  final String id;
  final String name;
  final String phoneNumber;
  final String gender;
  final String? chatId;
  final String language;
  final DateTime lastInteractionDate;
  final DateTime? nextReminderDate;
  final bool isActive;
  final double deposit;
  final String? tenantProfile;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? roomId;
  final RoomDto? room;

  TenantDto({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    this.chatId,
    required this.language,
    required this.lastInteractionDate,
    this.nextReminderDate,
    required this.isActive,
    required this.deposit,
    this.tenantProfile,
    required this.createdAt,
    required this.updatedAt,
    this.roomId,
    this.room,
  });

  factory TenantDto.fromJson(Map<String, dynamic> json) {
    return TenantDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'other',
      chatId: json['chatId']?.toString(),
      language: json['language']?.toString() ?? 'english',
      lastInteractionDate: _parseDateTime(json['lastInteractionDate']),
      nextReminderDate: json['nextReminderDate'] != null
          ? _parseDateTime(json['nextReminderDate'])
          : null,
      isActive: json['isActive'] ?? true,
      deposit: _parseDouble(json['deposit']),
      tenantProfile: json['tenantProfile']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      roomId: json['roomId']?.toString(),
      room: json['room'] != null
          ? RoomDto.fromJson(json['room'] as Map<String, dynamic>)
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

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'gender': gender,
      if (chatId != null) 'chatId': chatId,
      'language': language,
      'lastInteractionDate': lastInteractionDate.toIso8601String(),
      if (nextReminderDate != null)
        'nextReminderDate': nextReminderDate!.toIso8601String(),
      'isActive': isActive,
      'deposit': deposit,
      if (tenantProfile != null) 'tenantProfile': tenantProfile,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
      chatId: chatId,
      language: language,
      lastInteractionDate: lastInteractionDate,
      nextReminderDate: nextReminderDate,
      isActive: isActive,
      deposit: deposit,
      tenantProfile: tenantProfile,
      createdAt: createdAt,
      updatedAt: updatedAt,
      room: room?.toRoom(),
    );
  }
}