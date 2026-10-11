/// Utility for validating and normalizing phone numbers to E.164 format
/// compliant with Firestore security rules and local Pakistani mobile standards.
class PhoneFormatter {
  PhoneFormatter._();

  /// Normalizes a Pakistani phone number to international E.164 format (`+923XXXXXXXXX`).
  ///
  /// Examples:
  /// - `03001234567` -> `+923001234567`
  /// - `923001234567` -> `+923001234567`
  /// - `+923001234567` -> `+923001234567`
  /// - `0300-1234567` -> `+923001234567`
  static String normalizeToE164(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '';

    // Strip whitespaces, dashes, brackets
    var cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('92')) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('0')) {
      return '+92${cleaned.substring(1)}';
    }
    return '+92$cleaned';
  }

  /// Formats an E.164 or raw number into a readable local format (e.g. `0300 1234567`).
  static String formatDisplay(String phone) {
    final e164 = normalizeToE164(phone);
    if (e164.startsWith('+92') && e164.length == 13) {
      final code = '0${e164.substring(3, 6)}';
      final rest = e164.substring(6);
      return '$code $rest';
    }
    return phone;
  }

  /// Validates whether a phone number matches standard Pakistani mobile number format.
  static bool isValidPakistaniMobile(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(\+92|92|0)?3[0-9]{9}$').hasMatch(cleaned);
  }
}
