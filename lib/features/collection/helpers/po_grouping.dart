import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// One customer P.O. and the invoices billed under it.
class PoInvoiceGroup {
  const PoInvoiceGroup({required this.poNumber, required this.invoices});

  /// The P.O. as the first invoice spelled it (SAP is not consistent about
  /// case, so grouping is case-insensitive but display keeps a real value).
  final String poNumber;
  final List<CollectionItemModel> invoices;

  /// Stable identity for expansion state across rebuilds.
  String get key => poNumber.trim().toUpperCase();

  double get totalDue =>
      invoices.fold(0.0, (sum, i) => sum + i.toBeCollected);

  int get overdueCount => invoices.where((i) => i.isOverdue).length;
}

/// An account's invoices folded by P.O., in the order the list arrived.
///
/// [groups] holds every P.O. with the invoices under it, first appearance
/// first, so whatever sort the caller applied still decides which P.O. leads.
/// [ungrouped] is the tail of invoices that carry no P.O.; they are listed as
/// plain cards after the groups, because a group you cannot name is not a
/// group anyone would open.
class PoGrouping {
  const PoGrouping({required this.groups, required this.ungrouped});

  final List<PoInvoiceGroup> groups;
  final List<CollectionItemModel> ungrouped;

  bool get isEmpty => groups.isEmpty && ungrouped.isEmpty;

  /// Whether folding changes the picture at all. With no P.O. on any invoice
  /// the screen shows the flat list it always did.
  bool get hasGroups => groups.isNotEmpty;

  static PoGrouping of(List<CollectionItemModel> invoices) {
    final byKey = <String, List<CollectionItemModel>>{};
    final order = <String>[];
    final labels = <String, String>{};
    final ungrouped = <CollectionItemModel>[];

    for (final inv in invoices) {
      if (!inv.hasPoNumber) {
        ungrouped.add(inv);
        continue;
      }
      final label = inv.poNumber.trim();
      final key = label.toUpperCase();
      final bucket = byKey.putIfAbsent(key, () {
        order.add(key);
        labels[key] = label;
        return <CollectionItemModel>[];
      });
      bucket.add(inv);
    }

    return PoGrouping(
      groups: [
        for (final key in order)
          PoInvoiceGroup(poNumber: labels[key]!, invoices: byKey[key]!),
      ],
      ungrouped: ungrouped,
    );
  }
}
