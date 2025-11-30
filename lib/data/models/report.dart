import 'package:joul_v2/data/models/enum/report_language.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/room.dart';

class Report {
  final String id;
  final String problemDescription;
  ReportStatus status;
  ReportLanguage language;
  String? notes;
  final String tenantId;
  final String? roomId;
  Tenant? tenant;
  Room? room;

  Report({
    required this.id,
    required this.tenantId,
    this.roomId,
    required this.problemDescription,
    required this.status,
    required this.language,
    this.notes,
    this.tenant,
    this.room,
  });

  Report copyWith({
    String? id,
    String? tenantId,
    String? roomId,
    String? problemDescription,
    ReportStatus? status,
    ReportLanguage? language,
    String? notes,
    Tenant? tenant,
    Room? room,
  }) {
    return Report(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      problemDescription: problemDescription ?? this.problemDescription,
      status: status ?? this.status,
      language: language ?? this.language,
      notes: notes ?? this.notes,
      tenant: tenant ?? this.tenant,
      room: room ?? this.room,
    );
  }
}
