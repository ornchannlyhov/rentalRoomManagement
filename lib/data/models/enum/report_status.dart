enum ReportStatus {
  pending,
  inProgress,
  resolved,
  closed;

  String toApiString() {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.closed:
        return 'closed';
    }
  }

  static ReportStatus fromApiString(String value) {
    switch (value.toLowerCase()) {
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      case 'closed':
        return ReportStatus.closed;
      default:
        return ReportStatus.pending;
    }
  }
}
