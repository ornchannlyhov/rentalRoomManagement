import 'package:receipts_v2/model/enum/gender.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:json_annotation/json_annotation.dart';

part 'JsonSerializable/client.g.dart';

@JsonSerializable(explicitToJson: true)
class Client {
  final String id;
  final String name;
  final String phoneNumber;
  Room? room;
  Gender gender;

  Client(
      {required this.id,
      required this.name,
      required this.phoneNumber,
      required this.gender,
      this.room});

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

  Map<String, dynamic> toJson() => _$ClientToJson(this);
}
