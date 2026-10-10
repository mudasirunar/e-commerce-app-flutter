/// Utility class for handling money representations in Pakistani Rupees (PKR)
/// using exact integer minor units (paisa). 100 paisa = 1 PKR.
///
/// Prevents floating-point rounding errors and ensures authoritative parity
/// with Cloud Firestore schema and backend calculations.
class MoneyFormatter {
  const MoneyFormatter._();

  /// Converts a major PKR value (e.g. 4500.50) into integer paisa (450050).
  /// Rejects negative values unless allowNegative is explicitly true.
  static int pkrToMinor(num pkr, {bool allowNegative = false}) {
    if (!allowNegative && pkr < 0) {
      throw ArgumentError.value(pkr, 'pkr', 'Money amount cannot be negative');
    }
    // Round to avoid slight double representation discrepancies (e.g. 4500.5000000000001)
    return (pkr * 100).round();
  }

  /// Converts integer paisa into major PKR units (e.g. 450050 -> 4500.50).
  static double minorToPkr(int minorUnits) {
    return minorUnits / 100.0;
  }

  /// Formats integer paisa into standard display string.
  /// Example: 450000 -> "PKR 4,500.00"
  /// If [showPaisa] is false and paisa is 00, displays "PKR 4,500"
  static String format(int minorUnits, {bool prefix = true, bool showPaisa = true}) {
    final isNegative = minorUnits < 0;
    final absMinor = minorUnits.abs();
    final major = absMinor ~/ 100;
    final paisa = absMinor % 100;

    final majorString = _addCommas(major);
    final sign = isNegative ? '-' : '';
    final symbol = prefix ? 'PKR ' : '';

    if (!showPaisa && paisa == 0) {
      return '$symbol$sign$majorString';
    }

    final paisaString = paisa.toString().padLeft(2, '0');
    return '$symbol$sign$majorString.$paisaString';
  }

  /// Formats as compact display: e.g. "Rs 4,500"
  static String formatShort(int minorUnits) {
    return format(minorUnits, prefix: false);
  }

  /// Safely parses user input string into integer paisa.
  /// Handles "4500", "4,500", "4500.50", "PKR 4500", etc.
  /// Returns null if format is invalid.
  static int? parseToMinor(String input) {
    final cleaned = input
        .replaceAll('PKR', '')
        .replaceAll('Rs', '')
        .replaceAll(',', '')
        .trim();

    if (cleaned.isEmpty) return null;

    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;

    return (value * 100).round();
  }

  /// Adds comma separators to thousands.
  static String _addCommas(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
