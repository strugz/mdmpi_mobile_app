/// The remarks of a reconciliation step that names several invoices, each
/// with its own remark (update checklist item 20).
///
/// The server keeps one remark per step, so they are written into it one per
/// line, as Deposit remarks are: the remark for all of them first, then
/// "SI 700012703 - remark" for each invoice that has one, in the order the
/// sheet lists them. One step, so the case's stages count it once.
class BReconRemarks {
  BReconRemarks._();

  /// What the server stores for a step's remarks.
  static const int maxLength = 1000;

  static String compose({
    required String general,
    required List<String> invoiceNos,
    required Map<String, String> perInvoice,
  }) {
    final lines = <String>[
      if (general.trim().isNotEmpty) general.trim(),
      for (final no in invoiceNos)
        if ((perInvoice[no] ?? '').trim().isNotEmpty)
          'SI $no - ${perInvoice[no]!.trim().replaceAll(RegExp(r'\s*\n\s*'), ' ')}',
    ];
    return lines.join('\n');
  }
}
