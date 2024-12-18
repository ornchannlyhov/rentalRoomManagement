import 'package:json_annotation/json_annotation.dart';

part 'JsonSerializable/service.g.dart';

@JsonSerializable(explicitToJson: true)
class Service {
  final String id;
  final String name;
  final double price;

  Service({required this.id, required this.name, required this.price});

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceToJson(this);
  @override
  String toString() => 'name: $name';
}
