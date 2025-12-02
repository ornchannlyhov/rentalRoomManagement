class PaymentConfig {
  final String id;
  final String landlordId;
  final String paymentMethod; // "khqr", "aba_payway", "both", "none"
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final bool enableKhqr;
  final bool enableAbaPayWay;

  PaymentConfig({
    required this.id,
    required this.landlordId,
    required this.paymentMethod,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    required this.enableKhqr,
    required this.enableAbaPayWay,
  });

  PaymentConfig copyWith({
    String? id,
    String? landlordId,
    String? paymentMethod,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    bool? enableKhqr,
    bool? enableAbaPayWay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentConfig(
      id: id ?? this.id,
      landlordId: landlordId ?? this.landlordId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      enableKhqr: enableKhqr ?? this.enableKhqr,
      enableAbaPayWay: enableAbaPayWay ?? this.enableAbaPayWay,
    );
  }

  bool get hasKhqr => enableKhqr && (paymentMethod == 'khqr' || paymentMethod == 'both');
  bool get hasAbaPayWay => enableAbaPayWay && (paymentMethod == 'aba_payway' || paymentMethod == 'both');
  bool get hasAnyPaymentMethod => paymentMethod != 'none';
}