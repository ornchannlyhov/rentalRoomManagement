import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:receipts_v2/data/models/user.dart';

class UserDto {
  final String id;
  final String? username;
  final String? email;
  final String? token;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<BuildingDto>? buildings;

  UserDto({
    required this.id,
    this.username,
    this.email,
    this.token,
    this.createdAt,
    this.updatedAt,
    this.buildings,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      token: json['token']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      buildings: json['buildings'] != null
          ? (json['buildings'] as List)
              .map((b) => BuildingDto.fromJson(b as Map<String, dynamic>))
              .toList()
          : null,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (token != null) 'token': token,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (buildings != null)
        'buildings': buildings!.map((b) => b.toJson()).toList(),
    };
  }

  User toUser() {
    return User(
      id: id,
      username: username,
      email: email,
      token: token,
    );
  }
}
