// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../models/receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Receipt _$ReceiptFromJson(Map<String, dynamic> json) => Receipt(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      lastWaterUsed: (json['lastWaterUsed'] as num).toInt(),
      lastElectricUsed: (json['lastElectricUsed'] as num).toInt(),
      thisWaterUsed: (json['thisWaterUsed'] as num).toInt(),
      thisElectricUsed: (json['thisElectricUsed'] as num).toInt(),
      paymentStatus: $enumDecode(_$PaymentStatusEnumMap, json['paymentStatus']),
      room: json['room'] == null
          ? null
          : Room.fromJson(json['room'] as Map<String, dynamic>),
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => Service.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ReceiptToJson(Receipt instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'dueDate': instance.dueDate.toIso8601String(),
      'lastWaterUsed': instance.lastWaterUsed,
      'lastElectricUsed': instance.lastElectricUsed,
      'thisWaterUsed': instance.thisWaterUsed,
      'thisElectricUsed': instance.thisElectricUsed,
      'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'services': instance.services.map((e) => e.toJson()).toList(),
      'room': instance.room?.toJson(),
    };

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.paid: 'paid',
  PaymentStatus.overdue: 'overdue',
};
