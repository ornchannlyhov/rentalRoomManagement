import 'package:joul_v2/data/models/enum/report_language.dart';
import 'package:joul_v2/data/models/enum/report_priority.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/room.dart';

class Report {
  final String id;
  final String problemDescription;
  ReportStatus status;
  ReportPriority priority;
  ReportLanguage language;
  String? notes;
  Tenant? tenant;
  Room? room;

  Report({
    required this.id,
    required this.problemDescription,
    required this.status,
    required this.priority,
    required this.language,
    this.notes,
    this.tenant,
    this.room,
  });

  Report copyWith({
    String? id,
    String? problemDescription,
    ReportStatus? status,
    ReportPriority? priority,
    ReportLanguage? language,
    String? notes,
    Tenant? tenant,
    Room? room,
  }) {
    return Report(
      id: id ?? this.id,
      problemDescription: problemDescription ?? this.problemDescription,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      language: language ?? this.language,
      notes: notes ?? this.notes,
      tenant: tenant ?? this.tenant,
      room: room ?? this.room,
    );
  }
}


