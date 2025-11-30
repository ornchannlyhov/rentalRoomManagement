enum ReportStatus {
  pending,
  resolved;

  String toApiString() {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.resolved:
        return 'resolved';
    }
  }

  static ReportStatus fromApiString(String value) {
    switch (value.toLowerCase()) {
      case 'resolved':
        return ReportStatus.resolved;
      default:
        return ReportStatus.pending;
    }
  }
}
