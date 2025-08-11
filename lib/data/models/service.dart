import 'package:json_annotation/json_annotation.dart';

part '../dtos/service.g.dart';

@JsonSerializable() 
class Service {
  final String id;
  final String name;
  final double price;
  final String buildingId; 

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.buildingId, 
  });


  factory Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceToJson(this);

  @override
  String toString() => 'name: $name';
}