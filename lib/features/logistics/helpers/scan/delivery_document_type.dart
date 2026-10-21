import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';

/// The request forms a scanned document can belong to (plan §1, "Which
/// document belongs to which request").
enum DeliveryRequestForm {
  standardDelivery('Standard Delivery'),
  airSeaLand('Air/Sea/Land'),
  airSea('Air/Sea/Land HD'),
  hotlineDirect('Hotline Direct'),
  pullOut('Pull Out');

  const DeliveryRequestForm(this.label);

  final String label;
}

/// The kind of document photographed, read from its printed title.
enum DeliveryDocumentType {
  stockIssueSlip('Stock Issue Slip', {
    DeliveryRequestForm.standardDelivery,
    DeliveryRequestForm.airSeaLand,
    DeliveryRequestForm.airSea,
  }),
  inventoryTransferRequest('Inventory Transfer Request', {
    DeliveryRequestForm.airSeaLand,
    DeliveryRequestForm.airSea,
  }),
  inventoryTransfer('Inventory Transfer', {
    DeliveryRequestForm.airSeaLand,
    DeliveryRequestForm.airSea,
  }),
  acknowledgementReceipt('Acknowledgement Receipt', {
    DeliveryRequestForm.hotlineDirect,
    DeliveryRequestForm.airSea,
  }),
  materialsIssuanceSlip('Materials Issuance Slip', {
    DeliveryRequestForm.airSea,
    DeliveryRequestForm.airSeaLand,
  }),
  returnPullOutSlip('Return / Pull Out Slip', {DeliveryRequestForm.pullOut}),
  goodsIssue('Goods Issue', {
    DeliveryRequestForm.standardDelivery,
    DeliveryRequestForm.airSea,
    DeliveryRequestForm.airSeaLand,
  }),
  salesInvoice('Sales Invoice', {
    DeliveryRequestForm.airSea,
    DeliveryRequestForm.airSeaLand,
    DeliveryRequestForm.standardDelivery,
  }),
  deliveryReceipt('Delivery Receipt', {
    DeliveryRequestForm.airSea,
    DeliveryRequestForm.airSeaLand,
    DeliveryRequestForm.standardDelivery,
  }),
  reagentsIssueSlip('Reagents Issue Slip', {
    DeliveryRequestForm.standardDelivery,
    DeliveryRequestForm.hotlineDirect,
  }),

  /// No known title read. Never blocks anything.
  unknown('Unknown document', {});

  const DeliveryDocumentType(this.label, this.forms);

  final String label;

  /// The request forms this document is used for (decision 2026-10-15).
  final Set<DeliveryRequestForm> forms;

  /// The references this document prints, by their form label, or null
  /// when any reference read is kept. Anything else on the page (a code in
  /// the Comments, a number from another column) is not this document's
  /// reference: an Inventory Transfer carries its IT No. and the ITR it is
  /// based on, never the `AR26-239` someone typed into its comments
  /// (device run 2026-10-15).
  Set<String>? get referenceLabels => switch (this) {
        inventoryTransfer => const {'ITNo.:', 'ITRNo.:'},
        inventoryTransferRequest => const {'ITRNo.:'},
        goodsIssue => const {'GINo.:', 'ITNo.:'},
        salesInvoice => const {'SINo.:', 'DRNo.:', 'PONo.:'},
        deliveryReceipt => const {'DRNo.:', 'SINo.:', 'PONo.:', 'SIS#:'},
        stockIssueSlip => const {'SIS#:'},
        _ => null,
      };

  /// [references] narrowed to the ones this document prints
  /// ([referenceLabels]), order kept.
  List<String> keepOwnReferences(List<String> references) {
    final labels = referenceLabels;
    if (labels == null) return references;
    return [
      for (final r in references)
        if (labels.any(r.startsWith)) r,
    ];
  }

  /// Whether this document belongs on [form]. An unknown title is allowed.
  bool fits(DeliveryRequestForm form) =>
      this == DeliveryDocumentType.unknown || forms.contains(form);

  /// "An Inventory Transfer is for Air/Sea/Land and Air/Sea, not Standard
  /// Delivery.", or null when it fits [form].
  String? mismatchWarning(DeliveryRequestForm form) {
    if (fits(form)) return null;
    final names = [
      for (final f in DeliveryRequestForm.values)
        if (forms.contains(f)) f.label,
    ];
    final list = names.length <= 1
        ? names.join()
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    final article = RegExp('^[AEIOU]').hasMatch(label) ? 'An' : 'A';
    return '$article $label is for $list, not ${form.label}.';
  }

  /// Titles, the more specific first ("Inventory Transfer Request" before
  /// "Inventory Transfer"). A title line holds the title and at most the
  /// word ORIGINAL; a label such as "Delivery Receipt: DR 690014676" on a
  /// Sales Invoice has more on its line and is not a title.
  static final List<(DeliveryDocumentType, RegExp)> _titles = [
    for (final (type, pattern) in [
      (inventoryTransferRequest, r'INVENTORY\s+TRANSFER\s+REQUEST'),
      (inventoryTransfer, r'INVENTORY\s+TRANSFER'),
      (stockIssueSlip, r'STOCK\s+ISSUE\s+SLIP'),
      (reagentsIssueSlip, r'REAGENTS?\s+ISSUE\s+SLIP'),
      (acknowledgementReceipt, r'ACKNOWLEDGE?MENT\s+RECEIPT'),
      (materialsIssuanceSlip, r'MATERIALS?\s+ISSUANCE\s+SLIP'),
      (returnPullOutSlip, r'RETURN\s*/\s*PULL\s*[-\s]?OUT\s+SLIP'),
      (goodsIssue, r'GOODS\s+ISSUE'),
      (salesInvoice, r'SALES\s+INVOICE'),
      (deliveryReceipt, r'DELIVERY\s+RECEIPT'),
    ])
      (
        type,
        RegExp('^[^A-Za-z0-9]*$pattern[^A-Za-z0-9]*(ORIGINAL)?[^A-Za-z0-9]*\$',
            caseSensitive: false)
      ),
  ];

  /// The document's type from its title line. When several lines look like
  /// titles, the tallest (largest print) wins.
  static DeliveryDocumentType detect(List<OcrLine> lines) {
    DeliveryDocumentType best = unknown;
    var bestHeight = -1.0;
    for (final line in lines) {
      for (final (type, re) in _titles) {
        if (!re.hasMatch(line.text.trim())) continue;
        if (line.box.height > bestHeight) {
          best = type;
          bestHeight = line.box.height;
        }
        break;
      }
    }
    return best;
  }
}
