// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/building.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Building _$BuildingFromJson(Map<String, dynamic> json) => Building(
      id: json['id'] as String,
      name: json['name'] as String,
      rentPrice: (json['rentPrice'] as num).toDouble(),
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((e) => Room.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      electricPrice: (json['electricPrice'] as num).toDouble(),
      waterPrice: (json['waterPrice'] as num).toDouble(),
    );

Map<String, dynamic> _$BuildingToJson(Building instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rooms': instance.rooms.map((e) => e.toJson()).toList(),
      'rentPrice': instance.rentPrice,
      'electricPrice': instance.electricPrice,
      'waterPrice': instance.waterPrice,
    };
