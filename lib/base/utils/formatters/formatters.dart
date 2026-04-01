import 'package:intl/intl.dart';

class BFormatter {

  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('MM-dd-yyyy').format(date);
  }

 static String formatDate2(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    try {
      final dt = DateTime.parse(norm);
      return DateFormat('MMM d, yyyy HH:mm').format(dt);
    } catch (_) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

  static String formatDate3(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    try {
      final dt = DateTime.parse(norm);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
  }

  /// Formats datetime strings to a readable form with AM/PM.
  /// Example output: "Mar 5, 2026 04:31 PM"
  /// Accepts ISO-like strings, epoch (seconds/millis) or already-ISO; falls back
  /// to the original value on parse failure.
  static String formatDateWithAmPm(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) return value;
    try {
      final dt = DateTime.parse(norm);
      return DateFormat('MMM d, yyyy hh:mm a').format(dt);
    } catch (_) {
      return value;
    }
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  /// Formats a numeric value as an integer string (no decimals, no currency symbol).
  /// Uses locale-aware grouping (commas) and rounds the value to nearest integer.
  static String formatIntegerNoDecimal(double value) {
    return NumberFormat('#,##0', 'en_US').format(value.round());
  }

  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
    } else if (phoneNumber.length == 11) {
      return '(${phoneNumber.substring(0, 4)}) ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  static String formatDateTime(String inputDate) {
    try {
      // Parse the original string using the known format
      final originalFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");
      final dateTime = originalFormat.parse(inputDate);

      // Format it to the desired output
      final desiredFormat = DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS");

      return desiredFormat.format(dateTime);
    } catch (e) {
      return ''; // or handle error
    }
  }

  static String formatDateTimeCustomizable(
      String inputDate, String originalFormat, String desiredFormat) {
    try {
      final originalDateFormat = DateFormat(originalFormat);
      final dateTime = originalDateFormat.parse(inputDate);

      final desiredDateFormat = DateFormat(desiredFormat);
      return desiredDateFormat.format(dateTime);
    } catch (e) {
      return '';
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static bool isDaysAgo(DateTime date, int n) {
    final targetDate = DateTime.now().subtract(Duration(days: n));
    return date.year == targetDate.year &&
        date.month == targetDate.month &&
        date.day == targetDate.day;
  }

  static bool isWithinLastNDays(DateTime date, int n) {
    final now = DateTime.now();
    final nDaysAgo = now.subtract(Duration(days: n));
    return date.isAfter(nDaysAgo) && date.isBefore(now.add(Duration(days: 1)));
  }

  // New method for tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Normalize a date/time string to an ISO-8601 datetime string when possible.
  ///
  /// Accepts ISO-8601 input, epoch milliseconds (as a string/int), or epoch
  /// seconds (10-digit). Returns `null` for null/empty input or the original
  /// string as a fallback when parsing fails. Optionally convert to UTC.
  static String? normalizeToIsoDatetime(String? s, {bool toUtc = false}) {
    if (s == null) return null;
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;

    // Try ISO-8601 parse first
    try {
      final dt = DateTime.parse(trimmed);
      return toUtc ? dt.toUtc().toIso8601String() : dt.toIso8601String();
    } catch (_) {}

    // If it's a pure digits string, treat as epoch seconds or millis
    final digitsOnly = RegExp(r'^\d+$');
    if (digitsOnly.hasMatch(trimmed)) {
      try {
        final n = int.parse(trimmed);
        // 10-digit -> seconds, else -> millis
        final epochMs = trimmed.length == 10 ? n * 1000 : n;
        final dt = DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: toUtc);
        return toUtc ? dt.toUtc().toIso8601String() : dt.toIso8601String();
      } catch (_) {}
    }

    // Fallback: return original trimmed string
    return trimmed;
  }

  /// Formats picked-up / received datetime strings to 'MMM d, yyyy hh:mm a'.
  /// Example output: "Mar 5, 2026 04:31 PM".
  /// Returns original value if parsing fails.
  static String formatPickedUpAt(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) return value;
    try {
      final dt = DateTime.parse(norm);
      return DateFormat('MMM d, yyyy hh:mm a').format(dt);
    } catch (_) {
      return value;
    }
  }
}
