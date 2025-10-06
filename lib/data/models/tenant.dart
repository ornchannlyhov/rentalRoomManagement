import 'package:receipts_v2/data/models/enum/gender.dart';
import 'package:receipts_v2/data/models/room.dart';

class Tenant {
  final String id;
  final String name;
  final String phoneNumber;
  final Gender gender;
  Room? room;

  Tenant({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    this.room,
  });

  Tenant copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    Gender? gender,
    Room? room,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      room: room ?? this.room,
    );
  }
}
