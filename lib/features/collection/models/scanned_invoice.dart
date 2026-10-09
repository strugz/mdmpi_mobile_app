/// One invoice number printed on a client's voucher, as the AI read it.
class VoucherInvoiceLine {
  const VoucherInvoiceLine({
    required this.invoiceNo,
    this.label = '',
    this.amount,
  });

  /// As printed: prefixes and leading zeros kept.
  final String invoiceNo;

  /// 'SI', 'Invoice' or 'Sales Invoice'; '' when unknown.
  final String label;

  /// The amount printed for it on the voucher, shown for checking only.
  final double? amount;

  /// One element of the voucher prompt's JSON array; null when it names no
  /// invoice. Tolerant of the model's shapes: number or string amounts,
  /// "1,234.50", missing keys.
  static VoucherInvoiceLine? fromJson(Object? json) {
    if (json is! Map) return null;
    final no = '${json['Invoice No.'] ?? json['invoiceNo'] ?? ''}'.trim();
    if (no.isEmpty) return null;
    final rawAmount = json['Amount'] ?? json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(
            '${rawAmount ?? ''}'.replaceAll(RegExp(r'[^\d.\-]'), ''));
    return VoucherInvoiceLine(
      invoiceNo: no,
      label: '${json['Label'] ?? json['label'] ?? ''}'.trim(),
      amount: amount,
    );
  }

  /// Every invoice in the prompt's array, each number once, in order.
  static List<VoucherInvoiceLine> listFrom(List<dynamic> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (fromJson(item) case final line?)
          if (seen.add(line.invoiceNo.toUpperCase())) line,
    ];
  }
}

/// Where a scanned number stands against the account.
enum ScannedInvoiceStatus {
  /// An open invoice of this account: it can go in the cart.
  matched('In this account'),

  /// One digit off a single open invoice of this account (a likely misread):
  /// selected, but marked for the collector to check.
  likely('Close match, check the number'),

  /// An invoice of this client that is not open in this engagement.
  elsewhere('Not open in this engagement'),

  /// Reads as more than one of the account's invoices.
  ambiguous('Matches more than one invoice'),

  /// No invoice of this client.
  notFound('Not found in this account');

  const ScannedInvoiceStatus(this.label);

  final String label;

  bool get canAdd => this == matched || this == likely;
}

/// One tile of the Scanned Invoices screen.
class ScannedInvoice {
  const ScannedInvoice({
    required this.read,
    required this.status,
    this.label = '',
    this.amount,
    this.invoiceId,
    this.offline = false,
  });

  /// The number as read (or as the collector corrected it).
  final String read;
  final ScannedInvoiceStatus status;
  final String label;
  final double? amount;

  /// The invoice it matched, when [status] is matched or elsewhere.
  final String? invoiceId;

  /// Read by the phone itself because the AI could not be reached.
  final bool offline;

  ScannedInvoice asOffline() => ScannedInvoice(
        read: read,
        status: status,
        label: label,
        amount: amount,
        invoiceId: invoiceId,
        offline: true,
      );

  /// The same number for de-duplication across pages.
  String get key => (invoiceId ?? read).trim().toUpperCase();
}

/// What one scan did on the account's list: the banner above it.
class VoucherScanSummary {
  const VoucherScanSummary({
    this.selectedIds = const [],
    this.notFound = const [],
    this.unsure = 0,
    this.offline = false,
  });

  /// Invoices the scan ticked in the list.
  final List<String> selectedIds;

  /// Numbers read that are no invoice of this client.
  final List<String> notFound;

  /// Numbers that are the client's but not open here, or fit more than one.
  final int unsure;

  /// Read by the phone itself (no AI connection).
  final bool offline;

  bool get needsChecking => notFound.isNotEmpty || unsure > 0 || offline;
}
