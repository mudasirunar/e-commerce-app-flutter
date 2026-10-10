import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to parse and format Firestore timestamps and DateTime values consistently.
class DateFormatter {
  const DateFormatter._();

  /// Converts diverse timestamp representations (Timestamp, String ISO, int millis, DateTime) into DateTime.
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Converts DateTime into Firestore Timestamp or ISO string for JSON serialization.
  static dynamic toSerializable(DateTime? dt, {bool useTimestamp = true}) {
    if (dt == null) return null;
    return useTimestamp ? Timestamp.fromDate(dt) : dt.toIso8601String();
  }

  /// Formats date for display: e.g. "10 Oct 2026, 08:30 PM"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final local = dateTime.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;

    final hour24 = local.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour12:$minute $period';
  }

  /// Formats date only: e.g. "10 Oct 2026"
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final local = dateTime.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    return '${local.day} $month ${local.year}';
  }
}
