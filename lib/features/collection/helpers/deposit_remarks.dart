import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// One account a deposit covers, and how much of the deposit is its.
class BDepositLine {
  const BDepositLine({required this.account, required this.amount});

  final String account;
  final double amount;
}

/// A deposit's remarks, written for the collector (update checklist item
/// 13): one line per account, "Account - Amount", then an optional note.
///
///     Antipolo Doctors Hospital - 25,000.00
///     Ace Diagnostics Corp. - 5,000.00
///     Note: Morning run
///
/// A deposit is still not tied to an account's invoices; the lines are what
/// the deposit slip covers, written where the office reads them. Plain
/// figures without a peso sign, so the remarks stay plain SMS text.
class BDepositRemarks {
  BDepositRemarks._();

  /// The server keeps a deposit's remarks in 500 characters.
  static const int maxLength = 500;

  /// "Antipolo Doctors Hospital - 25,000.00".
  static String line(String account, double amount) =>
      '${account.trim().replaceAll(RegExp(r'\s+'), ' ')} - '
      '${BFormatter.formatPesoCurrency(amount, includeSymbol: false).trim()}';

  /// Every line, then "Note: [note]" when there is one.
  static String compose(List<BDepositLine> lines, {String note = ''}) {
    final n = note.trim().replaceAll(RegExp(r'\s+'), ' ');
    return [
      for (final l in lines) line(l.account, l.amount),
      if (n.isNotEmpty) 'Note: $n',
    ].join('\n');
  }

  /// "Account - 25,000.00": the account and the figure, or null for any
  /// other line (a note, or remarks written before the format).
  static ({String account, String amount})? parseLine(String line) {
    final m = _line.firstMatch(line.trim());
    return m == null ? null : (account: m.group(1)!, amount: m.group(2)!);
  }

  static final RegExp _line = RegExp(r'^(.+) - ([\d,]+\.\d{2})$');
}
