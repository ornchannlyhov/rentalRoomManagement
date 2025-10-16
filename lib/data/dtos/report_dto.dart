import 'package:receipts_v2/data/models/enum/report_language.dart';
import 'package:receipts_v2/data/models/enum/report_priority.dart';
import 'package:receipts_v2/data/models/enum/report_status.dart';
import 'package:receipts_v2/data/models/report.dart';
import 'package:receipts_v2/data/dtos/tenant_dto.dart';
import 'package:receipts_v2/data/dtos/room_dto.dart';

class ReportDto {
  final String id;
  final String tenantId;
  final String? roomId;
  final String problemDescription;
  final String status;
  final String? priority;
  final String? language;
  final String? notes;
  final TenantDto? tenant;
  final RoomDto? room;

  ReportDto({
    required this.id,
    required this.tenantId,
    this.roomId,
    required this.problemDescription,
    required this.status,
    this.priority,
    this.language,
    this.notes,
    this.tenant,
    this.room,
  });

  factory ReportDto.fromJson(Map<String, dynamic> json) {
    return ReportDto(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      roomId: json['roomId']?.toString(),
      problemDescription: json['problemDescription']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      priority: json['priority']?.toString(),
      language: json['language']?.toString(),
      notes: json['notes']?.toString(),
      tenant: json['tenant'] != null
          ? TenantDto.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
      room: json['room'] != null
          ? RoomDto.fromJson(json['room'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      if (roomId != null) 'roomId': roomId,
      'problemDescription': problemDescription,
      'status': status,
      if (priority != null) 'priority': priority,
      if (language != null) 'language': language,
      if (notes != null) 'notes': notes,
      if (tenant != null) 'tenant': tenant!.toJson(),
      if (room != null) 'room': room!.toJson(),
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'tenantId': tenantId,
      if (roomId != null) 'roomId': roomId,
      'problemDescription': problemDescription,
      'status': status,
      if (priority != null) 'priority': priority,
      'language': language ?? 'english',
      if (notes != null) 'notes': notes,
    };
  }

  Report toReport() {
    return Report(
      id: id,
      problemDescription: problemDescription,
      status: _mapStatus(status),
      priority: _mapPriority(priority),
      language: _mapLanguage(language),
      notes: notes,
      tenant: tenant?.toTenant(),
      room: room?.toRoom(),
    );
  }


  ReportStatus _mapStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'resolved':
        return ReportStatus.resolved;
      case 'inprogress':
      case 'in_progress':
        return ReportStatus.inProgress;
      default:
        return ReportStatus.pending;
    }
  }

  ReportPriority _mapPriority(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return ReportPriority.high;
      case 'medium':
        return ReportPriority.medium;
      case 'low':
        return ReportPriority.low;
      default:
        return ReportPriority.medium; 
    }
  }

  ReportLanguage _mapLanguage(String? value) {
    switch (value?.toLowerCase()) {
      case 'khmer':
        return ReportLanguage.khmer;
      case 'english':
      default:
        return ReportLanguage.english;
    }
  }
}
