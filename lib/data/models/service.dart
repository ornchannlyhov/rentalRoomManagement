class Service {
  final String id;
  final String name;
  final double price;
  final String buildingId;
  final List<String>? receiptIds;

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.buildingId,
    this.receiptIds,
  });

  Service copyWith({
    String? id,
    String? name,
    double? price,
    String? buildingId,
    List<String>? receiptIds,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      buildingId: buildingId ?? this.buildingId,
      receiptIds: receiptIds ?? this.receiptIds,
    );
  }
}