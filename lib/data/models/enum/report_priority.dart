enum ReportPriority {
  low,
  medium,
  high,
  urgent;

  String toApiString() => name;

  static ReportPriority fromApiString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return ReportPriority.low;
      case 'medium':
        return ReportPriority.medium;
      case 'high':
        return ReportPriority.high;
      case 'urgent':
        return ReportPriority.urgent;
      default:
        return ReportPriority.medium;
    }
  }
}