import 'package:joul_v2/data/dtos/building_dto.dart';
import 'package:joul_v2/data/models/user.dart';

class UserDto {
  final String id;
  final String? username;
  final String? phoneNumber;
  final bool? phoneVerified;
  final String? email;
  final String? fcmToken;
  final String? token;
  final List<BuildingDto>? buildings;

  UserDto({
    required this.id,
    this.username,
    this.phoneNumber,
    this.phoneVerified,
    this.email,
    this.fcmToken,
    this.token,
    this.buildings,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      phoneVerified: json['phoneVerified'] as bool?,
      email: json['email']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      token: json['token']?.toString(),
      buildings: json['buildings'] != null
          ? (json['buildings'] as List)
              .map((b) =>
                  BuildingDto.fromJson(Map<String, dynamic>.from(b as Map)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (username != null) 'username': username,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (phoneVerified != null) 'phoneVerified': phoneVerified,
      if (email != null) 'email': email,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (token != null) 'token': token,
      if (buildings != null)
        'buildings': buildings!.map((b) => b.toJson()).toList(),
    };
  }

  User toUser() {
    return User(
      id: id,
      username: username,
      phoneNumber: phoneNumber,
      phoneVerified: phoneVerified,
      email: email,
      fcmToken: fcmToken,
      token: token,
    );
  }
}
