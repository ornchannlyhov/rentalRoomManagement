// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/tenant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tenant _$TenantFromJson(Map<String, dynamic> json) => Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      room: json['room'] == null
          ? null
          : Room.fromJson(json['room'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TenantToJson(Tenant instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'gender': _$GenderEnumMap[instance.gender]!,
      'room': instance.room?.toJson(),
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.other: 'other',
};
