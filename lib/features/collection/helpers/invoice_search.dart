import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// How an account's invoice list is laid out (meeting of 2026-10-07, item 2).
enum InvoiceViewMode {
  /// Grouped by customer P.O.; each P.O. opens to its SIs.
  po('PO'),

  /// A flat list of SIs; the P.O. is not shown or searched.
  si('SI');

  const InvoiceViewMode(this.label);

  final String label;

  /// P.O. groups and P.O. numbers on the cards.
  bool get showsPo => this == po;

  String get searchHint => showsPo ? 'Search P.O. or SI' : 'Search SI';

  static InvoiceViewMode fromName(Object? name) =>
      values.firstWhere((m) => m.name == name, orElse: () => po);
}

/// Whether [item] matches the search box [query] in [mode]: the SI number
/// and its document references always; the P.O. only in P.O. mode, since in
/// SI mode it is not on screen and a hit on a hidden field reads as a bug.
bool invoiceMatchesSearch(
    CollectionItemModel item, String query, InvoiceViewMode mode) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return item.id.toLowerCase().contains(q) ||
      (mode.showsPo && item.poNumber.toLowerCase().contains(q)) ||
      item.documentReferences.any((ref) => ref.toLowerCase().contains(q));
}
