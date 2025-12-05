/// Notification item model for storing notifications in Hive
class NotificationItem {
  final String id;
  final String type; // NEW_RECEIPT, NEW_USAGE_INPUT, PAYMENT_RECEIVED, etc.
  final String title;
  final String message;
  final String? receiptId;
  final String? reportId;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.receiptId,
    this.reportId,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? receiptId,
    String? reportId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      receiptId: receiptId ?? this.receiptId,
      reportId: reportId ?? this.reportId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
