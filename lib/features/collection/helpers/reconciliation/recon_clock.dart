/// Days for the Reconciliation Tracker, counted the same on every device.
///
/// Every time is turned into Philippine wall-clock time (+08:00) and carried
/// in a UTC `DateTime` whose fields *are* that wall-clock time, so neither a
/// Windows desk in another time zone nor daylight saving can move a day.
///
/// - A stamp with no offset (what the phone writes) is already Philippine
///   wall-clock time.
/// - A stamp ending in `Z` or with an offset is converted to +08:00. Read as
///   device-local instead, a `2026-09-27T23:30:00Z` would land on the 27th
///   when in Manila it is already the 28th.
class BReconClock {
  BReconClock._();

  static const Duration _phOffset = Duration(hours: 8);

  static final RegExp _hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

  /// [stamp] as Philippine wall-clock time, or null when unreadable.
  static DateTime? parse(String? stamp) {
    final s = (stamp ?? '').trim();
    if (s.isEmpty) return null;
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return null;
    if (_hasOffset.hasMatch(s)) return parsed.toUtc().add(_phOffset);
    return DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour,
        parsed.minute, parsed.second, parsed.millisecond, parsed.microsecond);
  }

  /// The real instant [now] as Philippine wall-clock time.
  static DateTime fromInstant(DateTime now) => now.toUtc().add(_phOffset);

  /// [instant] as the phone stamps a step: Manila wall-clock time, no offset
  /// (`2026-09-28T10:05:00`), whatever the device's time zone.
  static String stamp(DateTime instant) => format(fromInstant(instant));

  /// A wall-clock time from [parse] or [fromInstant] in the form [stamp] uses.
  static String format(DateTime wallClock) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${wallClock.year.toString().padLeft(4, '0')}-${two(wallClock.month)}'
        '-${two(wallClock.day)}T${two(wallClock.hour)}:${two(wallClock.minute)}'
        ':${two(wallClock.second)}';
  }

  /// The calendar day of a wall-clock time from [parse] or [fromInstant].
  static DateTime day(DateTime wallClock) =>
      DateTime.utc(wallClock.year, wallClock.month, wallClock.day);

  /// Whole calendar days from [from] to [to], both wall-clock times.
  /// 23:59 to 00:01 the next day is one day, not zero.
  static int daysBetween(DateTime from, DateTime to) =>
      day(to).difference(day(from)).inDays;
}
