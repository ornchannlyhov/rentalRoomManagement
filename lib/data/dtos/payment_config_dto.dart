import 'package:joul_v2/data/models/payment_config.dart';

class PaymentConfigDto {
  final String id;
  final String landlordId;
  final String paymentMethod;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final bool enableKhqr;
  final bool enableAbaPayWay;

  PaymentConfigDto({
    required this.id,
    required this.landlordId,
    required this.paymentMethod,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    required this.enableKhqr,
    required this.enableAbaPayWay,
  });

  factory PaymentConfigDto.fromJson(Map<String, dynamic> json) {
    return PaymentConfigDto(
      id: json['id']?.toString() ?? '',
      landlordId: json['landlordId']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'none',
      bankName: json['bankName']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      bankAccountName: json['bankAccountName']?.toString(),
      enableKhqr: json['enableKhqr'] as bool? ?? false,
      enableAbaPayWay: json['enableAbaPayWay'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'landlordId': landlordId,
      'paymentMethod': paymentMethod,
      if (bankName != null) 'bankName': bankName,
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (bankAccountName != null) 'bankAccountName': bankAccountName,
      'enableKhqr': enableKhqr,
      'enableAbaPayWay': enableAbaPayWay,
    };
  }

  PaymentConfig toPaymentConfig() {
    return PaymentConfig(
      id: id,
      landlordId: landlordId,
      paymentMethod: paymentMethod,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      bankAccountName: bankAccountName,
      enableKhqr: enableKhqr,
      enableAbaPayWay: enableAbaPayWay,
    );
  }
}