import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class BFormatter {
  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('MM-dd-yyyy').format(date);
  }

  // The display formatters below all go through [parseLocal], so a server
  // stamp carrying a 'Z' is shown in the reader's own timezone rather than in
  // UTC. Each keeps the fallback it had: the raw value, or its first ten
  // characters, when the string is not a date.

  static String formatDate2(String value) {
    if (value.isEmpty) return '';
    final dt = BFormatter.parseLocal(value);
    if (dt == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    return DateFormat('MMM d, yyyy HH:mm').format(dt);
  }

  static String formatDate3(String value) {
    if (value.isEmpty) return '';
    final dt = BFormatter.parseLocal(value);
    if (dt == null) {
      return value.length >= 10 ? value.substring(0, 10) : value;
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }

  /// Formats datetime strings to a readable form with AM/PM.
  /// Example output: "Mar 5, 2026 04:31 PM"
  /// Accepts ISO-like strings, epoch (seconds/millis) or already-ISO; falls back
  /// to the original value on parse failure.
  static String formatDateWithAmPm(String value) {
    if (value.isEmpty) return '';
    final dt = BFormatter.parseLocal(value);
    if (dt == null) return value;
    return DateFormat('MMM d, yyyy hh:mm a').format(dt);
  }

  /// Time of day only, e.g. "04:31 PM". Falls back to the raw value.
  static String formatTimeAmPm(String value) {
    if (value.isEmpty) return '';
    final dt = BFormatter.parseLocal(value);
    if (dt == null) return value;
    return DateFormat('hh:mm a').format(dt);
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
  static String formatPesoCurrency(double amount, {bool includeSymbol = true}) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: includeSymbol ? '₱' : '',
      decimalDigits: 2,
    ).format(amount);
  }

  /// Read a money amount back out of a text field.
  ///
  /// The inverse of [formatPesoCurrency], and the only way money fields should
  /// be parsed. A bare `double.tryParse` returns null for anything carrying a
  /// thousands separator, a peso sign or a stray space — and every call site
  /// wrote `?? 0` after it, so a perfectly readable "1,000" was silently
  /// recorded as zero. Whatever the collector can see in the field, this
  /// reads.
  ///
  /// Only the first decimal point counts, so a fat-fingered "12.34.5" is 12.34
  /// rather than 12.345: an extra keystroke must never change the magnitude.
  static double parseAmount(String? raw) {
    if (raw == null) return 0;
    final sanitized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (sanitized.isEmpty) return 0;
    final parts = sanitized.split('.');
    final cleaned = parts.length > 1 ? '${parts[0]}.${parts[1]}' : parts[0];
    return double.tryParse(cleaned) ?? 0;
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

  /// Memo for [daysPastFromString], keyed by the raw string, cleared when the
  /// calendar day turns over.
  ///
  /// The answer only changes once a day, but the collection lists ask for it
  /// constantly: filtering, sorting and drawing a bucket of 4,500 invoices ran
  /// this 4,500 times per rebuild and spent 180ms of a 188ms pass inside
  /// DateTime.parse. Distinct due dates number in the hundreds, so the map
  /// stays small.
  static final Map<String, int> _daysPastCache = {};
  static DateTime? _daysPastCacheDay;

  /// Parses a date string (attempting ISO / epoch forms) and returns days past due
  /// relative to now. Positive means overdue. Returns 0 for invalid input or not overdue.
  static int daysPastFromString(String? dateStr, {DateTime? now}) {
    if (dateStr == null || dateStr.isEmpty) return 0;
    // An injected clock is a test's or a caller's own reference point, so it
    // neither reads nor fills the cache.
    if (now != null) return _daysPastUncached(dateStr, now);

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (_daysPastCacheDay != day) {
      _daysPastCache.clear();
      _daysPastCacheDay = day;
    }
    final hit = _daysPastCache[dateStr];
    if (hit != null) return hit;
    return _daysPastCache[dateStr] = _daysPastUncached(dateStr, today);
  }

  static int _daysPastUncached(String dateStr, DateTime now) {
    final norm = normalizeToIsoDatetime(dateStr);
    if (norm == null) return 0;
    try {
      return daysBetweenNow(DateTime.parse(norm), now: now);
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

  /// A stamp as a [DateTime] in the reader's own timezone, or null when the
  /// string is not a date at all.
  ///
  /// The `.toLocal()` is the whole point. The server sends ISO stamps with a
  /// `Z`, [DateTime.parse] returns a UTC [DateTime], and both `DateFormat` and
  /// the `.year`/`.month`/`.day` fields then read UTC values off it. At UTC+8
  /// that printed the wrong time on every card and filed every engagement
  /// recorded before 08:00 under the previous calendar day.
  ///
  /// Null, not a throw and not a fallback string: the callers that used to
  /// swallow a parse failure silently could not tell a missing date from a
  /// malformed one, and both were being dropped without a trace.
  static DateTime? parseLocal(String? value) {
    final norm = normalizeToIsoDatetime(value);
    if (norm == null) return null;
    try {
      return DateTime.parse(norm).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Memo for [localDayKey], keyed by the raw stamp.
  ///
  /// Unlike [_daysPastCache] this never goes stale: which local day a stamp
  /// falls on is fixed the moment the stamp is written, and does not change at
  /// midnight. Distinct stamps over a month number in the hundreds; the cap is
  /// only there so a long-lived session cannot grow it without bound.
  static final Map<String, String> _localDayCache = {};

  /// The local calendar day of a stamp, as `yyyy-MM-dd`. Null when the string
  /// is not a date.
  static String? localDayKey(String? value) {
    if (value == null || value.isEmpty) return null;
    final hit = _localDayCache[value];
    if (hit != null) return hit;
    final dt = parseLocal(value);
    if (dt == null) return null;
    if (_localDayCache.length > 5000) _localDayCache.clear();
    return _localDayCache[value] = DateFormat('yyyy-MM-dd').format(dt);
  }

  /// Formats picked-up / received datetime strings to 'MMM d, yyyy hh:mm a'.
  /// Example output: "Mar 5, 2026 04:31 PM".
  /// Returns original value if parsing fails.
  static String formatPickedUpAt(String value) {
    if (value.isEmpty) return '';
    final dt = BFormatter.parseLocal(value);
    if (dt == null) return value;
    return DateFormat('MMM d, yyyy hh:mm a').format(dt);
  }
}

/// Check numbers: the numeric keypad and digits only, on every form that asks
/// for one (Record Deposit, Field Engagement, batch engagement). Some opened
/// the full keyboard and one let letters in; a pasted "CHK-123" now keeps
/// "123".
class BCheckNumberInput {
  BCheckNumberInput._();

  static const TextInputType keyboardType = TextInputType.number;

  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(20),
  ];
}

/// Money fields that format as you type, the same rules as the Collection web:
/// "7200000" reads "7,200,000" while it is typed, digits and one decimal point
/// only, at most two centavos, and [finalize] (see [BAmountBlurPad]) makes it
/// "7,200,000.00" once the field is left. The caret stays after the digit it
/// was after, so inserting or deleting in the middle of a number never throws
/// it to the end. Positive amounts only; read the text back with
/// [BFormatter.parseAmount], which drops the commas.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final RegExp _significant = RegExp(r'[0-9.]');

  /// Digits and one dot, at most two decimals, thousands separators on the
  /// whole part. A second dot is dropped rather than moving the decimal place
  /// (one stray keystroke used to turn "12.34.5" into 12.345), and the dot is
  /// kept the moment it is typed so centavos can be entered at all.
  static String format(String raw) {
    final sanitized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final dot = sanitized.indexOf('.');
    var whole = dot == -1 ? sanitized : sanitized.substring(0, dot);
    String? frac;
    if (dot != -1) {
      final rest = sanitized.substring(dot + 1).replaceAll('.', '');
      frac = rest.length > 2 ? rest.substring(0, 2) : rest;
    }

    whole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (whole.isEmpty && frac != null) whole = '0';
    final grouped = whole.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return frac == null ? grouped : '$grouped.$frac';
  }

  /// "7,200,000" → "7,200,000.00" when the field is left; blank stays blank.
  static String finalize(String raw) {
    final formatted = format(raw);
    if (formatted.isEmpty) return '';
    final parts = formatted.split('.');
    final frac = parts.length > 1 ? parts[1] : '';
    return '${parts[0]}.${frac.padRight(2, '0')}';
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final raw = newValue.text;
    final caret = newValue.selection.end < 0
        ? raw.length
        : newValue.selection.end.clamp(0, raw.length);
    // How many digits and dots sit before the caret: the same count, in the
    // formatted text, is where the caret goes back.
    var keep = 0;
    for (var i = 0; i < caret; i++) {
      if (_significant.hasMatch(raw[i])) keep++;
    }

    final text = format(raw);
    var offset = 0;
    if (keep > 0) {
      offset = text.length;
      var seen = 0;
      for (var i = 0; i < text.length; i++) {
        if (_significant.hasMatch(text[i])) seen++;
        if (seen == keep) {
          offset = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
