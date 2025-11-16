import 'dart:io';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/models/room.dart';

class Tenant {
  final String id;
  final String name;
  final String phoneNumber;
  final Gender gender;
  final String? chatId;
  final String language;
  final double deposit;
  final String? tenantProfile;

  Room? room;

  File? imageFile;

  Tenant({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    this.chatId,
    required this.language,
    required this.deposit,
    this.tenantProfile,
    this.room,
    this.imageFile, 
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
    File? imageFile, 
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      chatId: chatId ?? this.chatId,
      language: language ?? this.language,
      deposit: deposit ?? this.deposit,
      tenantProfile: tenantProfile ?? this.tenantProfile,
      room: room ?? this.room,
      imageFile: imageFile ?? this.imageFile, 
    );
  }
}
