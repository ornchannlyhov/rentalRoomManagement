// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      room: json['room'] == null
          ? null
          : Room.fromJson(json['room'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'room': instance.room?.toJson(),
    };
