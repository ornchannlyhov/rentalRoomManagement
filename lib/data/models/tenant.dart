import 'package:receipts_v2/data/models/enum/gender.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:json_annotation/json_annotation.dart';

part '../dtos/tenant.g.dart';

@JsonSerializable(explicitToJson: true)
class Tenant {
  final String id;
  final String name;
  final String phoneNumber;
  final Gender gender;
  late final Room? room;

  Tenant({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.gender,
    this.room,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) => _$TenantFromJson(json);
  Map<String, dynamic> toJson() => _$TenantToJson(this);

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
