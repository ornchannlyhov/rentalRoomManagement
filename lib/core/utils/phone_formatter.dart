class PhoneFormatter {
  /// Formats a phone number to E.164 format (+855...)
  /// Returns null if the phone number is invalid
  static String? format(String phone) {
    // Remove any non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Handle local format (starting with 0)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Handle international format without + (starting with 855)
    if (cleaned.startsWith('855')) {
      cleaned = cleaned.substring(3);
    }

    // Basic validation for Cambodia phone numbers
    // Usually 8 or 9 digits after country code
    if (cleaned.length < 8 || cleaned.length > 9) {
      return null;
    }

    return '+855$cleaned';
  }

  /// Validates if a string is a valid phone number
  static bool isValid(String phone) {
    return format(phone) != null;
  }
}
