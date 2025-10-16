enum ReportLanguage {
  english,
  khmer,
  chinese;

  String toApiString() => name;

  static ReportLanguage fromApiString(String value) {
    switch (value.toLowerCase()) {
      case 'english':
        return ReportLanguage.english;
      case 'khmer':
        return ReportLanguage.khmer;
      case 'chinese':
        return ReportLanguage.chinese;
      default:
        return ReportLanguage.english;
    }
  }
}