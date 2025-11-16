import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/models/room.dart';

class Tenant {
  final String id;
  final String name;
  final String phoneNumber;
  final Gender gender;
  final String? chatId;
  final String language;
  final DateTime lastInteractionDate;
  final DateTime? nextReminderDate;
  final bool isActive;
  final double deposit;
  final String? tenantProfile;
  final DateTime createdAt;
  final DateTime updatedAt;
  Room? room;

  Tenant({
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
    this.room,
  });

  Tenant copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    Gender? gender,
    String? chatId,
    String? language,
    DateTime? lastInteractionDate,
    DateTime? nextReminderDate,
    bool? isActive,
    double? deposit,
    String? tenantProfile,
    DateTime? createdAt,
    DateTime? updatedAt,
    Room? room,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      chatId: chatId ?? this.chatId,
      language: language ?? this.language,
      lastInteractionDate: lastInteractionDate ?? this.lastInteractionDate,
      nextReminderDate: nextReminderDate ?? this.nextReminderDate,
      isActive: isActive ?? this.isActive,
      deposit: deposit ?? this.deposit,
      tenantProfile: tenantProfile ?? this.tenantProfile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      room: room ?? this.room,
    );
  }
}