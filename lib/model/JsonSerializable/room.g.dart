// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
      id: json['id'] as String,
      roomNumber: json['roomNumber'] as String,
      roomStatus: $enumDecode(_$RoomStatusEnumMap, json['roomStatus']),
      price: (json['price'] as num).toDouble(),
      building: json['building'] == null
          ? null
          : Building.fromJson(json['building'] as Map<String, dynamic>),
      client: json['client'] == null
          ? null
          : Client.fromJson(json['client'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
      'id': instance.id,
      'roomNumber': instance.roomNumber,
      'building': instance.building?.toJson(),
      'client': instance.client?.toJson(),
      'roomStatus': _$RoomStatusEnumMap[instance.roomStatus]!,
      'price': instance.price,
    };

const _$RoomStatusEnumMap = {
  RoomStatus.available: 'available',
  RoomStatus.occupied: 'occupied',
};
