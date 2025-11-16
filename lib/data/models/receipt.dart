import 'package:joul_v2/data/models/enum/payment_status.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/service.dart';

class Receipt {
  final String id;
  final DateTime date;
  final DateTime dueDate;
  int lastWaterUsed;
  int lastElectricUsed;
  final int thisWaterUsed;
  final int thisElectricUsed;
  PaymentStatus paymentStatus;
  List<String> serviceIds;
  Room? room;

  // Private field for services
  List<Service> _services;

  Receipt({
    required this.id,
    required this.date,
    required this.dueDate,
    required this.lastWaterUsed,
    required this.lastElectricUsed,
    required this.thisWaterUsed,
    required this.thisElectricUsed,
    required this.paymentStatus,
    this.room,
    List<Service> services = const [],
    List<String>? serviceIds,
  })  : _services = List<Service>.from(services),
        serviceIds = serviceIds ?? services.map((s) => s.id).toList();

  List<Service> get services => _services;

  set services(List<Service> newServices) {
    _services = List<Service>.from(newServices);
    serviceIds = newServices.map((s) => s.id).toList();
  }

  int get waterUsage {
    if (thisWaterUsed < lastWaterUsed) {
      throw ArgumentError(
          'Current water usage ($thisWaterUsed) cannot be less than last usage ($lastWaterUsed)');
    }
    return thisWaterUsed - lastWaterUsed;
  }

  int get electricUsage {
    if (thisElectricUsed < lastElectricUsed) {
      throw ArgumentError(
          'Current electric usage ($thisElectricUsed) cannot be less than last usage ($lastElectricUsed)');
    }
    return thisElectricUsed - lastElectricUsed;
  }

  double get waterPrice {
    _validateRoom();
    return waterUsage * room!.building!.waterPrice;
  }

  double get electricPrice {
    _validateRoom();
    return electricUsage * room!.building!.electricPrice;
  }

  double get totalServicePrice =>
      services.fold(0.0, (total, service) => total + service.price);

  /// Get the rent price - prioritizes room's unique price, falls back to building's default rent price
  double get roomPrice {
    _validateRoom();
    // If room has a unique price (non-zero), use it
    // Otherwise, fall back to building's default rent price
    if (room!.price > 0) {
      return room!.price;
    }
    return room!.building!.rentPrice;
  }

  /// Calculate total price including utilities, services and rent
  double get totalPrice =>
      waterPrice + electricPrice + totalServicePrice + roomPrice;

  void _validateRoom() {
    if (room == null) {
      throw StateError('Room must be set before calculating prices');
    }
    if (room!.building == null) {
      throw StateError('Room must have a building reference');
    }
  }

  Receipt copyWith({
    String? id,
    DateTime? date,
    DateTime? dueDate,
    int? lastWaterUsed,
    int? lastElectricUsed,
    int? thisWaterUsed,
    int? thisElectricUsed,
    PaymentStatus? paymentStatus,
    List<Service>? services,
    List<String>? serviceIds,
    Room? room,
  }) {
    return Receipt(
      id: id ?? this.id,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      lastWaterUsed: lastWaterUsed ?? this.lastWaterUsed,
      lastElectricUsed: lastElectricUsed ?? this.lastElectricUsed,
      thisWaterUsed: thisWaterUsed ?? this.thisWaterUsed,
      thisElectricUsed: thisElectricUsed ?? this.thisElectricUsed,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      services: services ?? List<Service>.from(this.services),
      serviceIds: serviceIds ?? List<String>.from(this.serviceIds),
      room: room ?? this.room,
    );
  }
}
