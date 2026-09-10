import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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

  /// Time of day only, e.g. "04:31 PM". Falls back to the raw value.
  static String formatTimeAmPm(String value) {
    if (value.isEmpty) return '';
    final norm = BFormatter.normalizeToIsoDatetime(value);
    if (norm == null) return value;
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(norm));
    } catch (_) {
      return value;
    }
  }

  /// "12:46 PM → 12:52 PM · Sep 10, 2026" when both stamps fall on the same
  /// day; otherwise each stamp is shown with its own date. Either side may be
  /// empty. Used for start/end pairs where a duration is what the reader wants.
  static String formatTimeRange(String start, String end) {
    final hasStart = start.trim().isNotEmpty;
    final hasEnd = end.trim().isNotEmpty;
    if (!hasStart && !hasEnd) return '';
    if (hasStart && hasEnd) {
      final sameDay = formatDate3(start) == formatDate3(end);
      if (sameDay) {
        return '${formatTimeAmPm(start)} → ${formatTimeAmPm(end)} · ${formatDate3(start)}';
      }
      return '${formatDateWithAmPm(start)} → ${formatDateWithAmPm(end)}';
    }
    return formatDateWithAmPm(hasStart ? start : end);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  /// Format [amount] as Philippine Peso with comma-separated thousands.
  ///
  /// Returns a string like `₱25,000.00`. Pass [includeSymbol] `false` to omit
  /// the `₱` prefix (e.g. when the caller prepends its own symbol).
  static String formatPesoCurrency(double amount,
      {bool includeSymbol = true}) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: includeSymbol ? '₱' : '',
      decimalDigits: 2,
    ).format(amount);
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

  /// Returns number of whole days between [date] and now.
  /// Positive when [date] is in the past (i.e. days past due), zero if today or parsing failed.
  static int daysBetweenNow(DateTime date, {DateTime? now}) {
    try {
      final base = now ?? DateTime.now();
      return base.difference(date).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Parses a date string (attempting ISO / epoch forms) and returns days past due
  /// relative to now. Positive means overdue. Returns 0 for invalid input or not overdue.
  static int daysPastFromString(String? dateStr, {DateTime? now}) {
    if (dateStr == null || dateStr.isEmpty) return 0;
    final norm = normalizeToIsoDatetime(dateStr);
    if (norm == null) return 0;
    try {
      final dt = DateTime.parse(norm);
      return daysBetweenNow(dt, now: now);
    } catch (_) {
      return 0;
    }
  }

  /// Format a human readable overdue string. If days > 0 returns "N days overdue",
  /// if 0 returns "Due today", if negative returns "Due in N days".
  static String formatDaysOverdue(int days) {
    if (days > 1) return '$days days overdue';
    if (days == 1) return '1 day overdue';
    if (days == 0) return 'Due today';
    return 'Due in ${-days} days';
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

/// Input formatter that adds comma thousand-separators while typing.
/// Keeps decimal part intact. Works for positive numbers only.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _intFormat = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Preserve selection index later
    final selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;

    // Remove all characters except digits and dot
    final sanitized = newValue.text.replaceAll(RegExp('[^0-9\.]'), '');

    // If more than one dot, keep only first
    final parts = sanitized.split('.');
    final intPartRaw = parts[0];
    final decPartRaw = parts.length > 1 ? parts.sublist(1).join('') : '';

    // Format integer part with commas
    String formattedInt;
    try {
      formattedInt = _intFormat.format(int.parse(intPartRaw.isEmpty ? '0' : intPartRaw));
    } catch (_) {
      // Fallback: use raw integer part
      formattedInt = intPartRaw;
    }

    final newText = decPartRaw.isNotEmpty ? '$formattedInt.$decPartRaw' : formattedInt;

    // Recalculate selection
    final selectionIndex = newText.length - selectionIndexFromTheRight;
    final boundedIndex = selectionIndex.clamp(0, newText.length);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: boundedIndex),
    );
  }
}
