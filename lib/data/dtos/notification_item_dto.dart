import 'package:joul_v2/data/models/notification_item.dart';

/// DTO for serializing/deserializing NotificationItem to/from JSON for Hive storage
class NotificationItemDto {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? receiptId;
  final String? reportId;
  final String createdAt;
  final bool isRead;

  NotificationItemDto({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.receiptId,
    this.reportId,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) {
    return NotificationItemDto(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      receiptId: json['receiptId'] as String?,
      reportId: json['reportId'] as String?,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'receiptId': receiptId,
      'reportId': reportId,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  factory NotificationItemDto.fromModel(NotificationItem model) {
    return NotificationItemDto(
      id: model.id,
      type: model.type,
      title: model.title,
      message: model.message,
      receiptId: model.receiptId,
      reportId: model.reportId,
      createdAt: model.createdAt.toIso8601String(),
      isRead: model.isRead,
    );
  }

  NotificationItem toModel() {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      receiptId: receiptId,
      reportId: reportId,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      isRead: isRead,
    );
  }
}
