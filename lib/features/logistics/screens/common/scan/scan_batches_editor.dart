import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

/// The batches being edited in the scan's Edit item dialog: one set of
/// text fields per batch. The dialog owns it and disposes it.
class ScanBatchesDraft {
  ScanBatchesDraft(List<InventoryBatchModel> batches)
      : rows = [for (final b in batches) ScanBatchRow.from(b)];

  final List<ScanBatchRow> rows;

  void add() => rows.add(ScanBatchRow.from(null));

  void removeAt(int i) => rows.removeAt(i).dispose();

  /// The batches as typed. A row left fully empty is dropped; an empty
  /// quantity is 0, as the scan stores a batch with no printed quantity.
  List<InventoryBatchModel> get batches => [
        for (final r in rows)
          if (!r.isEmpty)
            InventoryBatchModel(
              batchSerial: r.serial.text.trim(),
              batchQuantity: parseQty(r.qty.text) ?? 0,
              expiryDate: r.expiry.text.trim(),
            ),
      ];

  /// A batch quantity as typed ("1,000.50" too), or null when it is not a
  /// number.
  static double? parseQty(String text) =>
      double.tryParse(text.trim().replaceAll(',', ''));

  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
  }
}

/// One batch's text fields in a [ScanBatchesDraft].
class ScanBatchRow {
  ScanBatchRow.from(InventoryBatchModel? b)
      : serial = TextEditingController(text: b?.batchSerial ?? ''),
        qty = TextEditingController(
            text: b == null || b.batchQuantity == 0
                ? ''
                : _qty(b.batchQuantity)),
        expiry = TextEditingController(text: b?.expiryDate ?? '');

  final TextEditingController serial;
  final TextEditingController qty;
  final TextEditingController expiry;

  bool get isEmpty =>
      serial.text.trim().isEmpty &&
      qty.text.trim().isEmpty &&
      expiry.text.trim().isEmpty;

  static String _qty(double q) => q % 1 == 0 ? q.toInt().toString() : '$q';

  void dispose() {
    serial.dispose();
    qty.dispose();
    expiry.dispose();
  }
}

/// The "Batches" part of the scan's Edit item dialog: each batch as a small
/// group (Batch / Serial #, then Qty and Expiry side by side, which fits a
/// 360 px phone), a remove button per batch, and "Add batch".
class ScanBatchesEditor extends StatefulWidget {
  const ScanBatchesEditor({super.key, required this.draft});

  final ScanBatchesDraft draft;

  @override
  State<ScanBatchesEditor> createState() => _ScanBatchesEditorState();
}

class _ScanBatchesEditorState extends State<ScanBatchesEditor> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = widget.draft.rows;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Batches', style: theme.textTheme.titleSmall),
              const SizedBox(width: BSizes.sm),
              if (rows.isNotEmpty)
                Text('${rows.length}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: BSizes.xs),
              child: Text('No batch read.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          for (var i = 0; i < rows.length; i++)
            _BatchGroup(
              key: ObjectKey(rows[i]),
              index: i,
              row: rows[i],
              onRemove: () => setState(() => widget.draft.removeAt(i)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('scanBatchAdd'),
              icon: const Icon(Iconsax.add, size: BSizes.iconSm),
              label: const Text('Add batch'),
              onPressed: () => setState(widget.draft.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchGroup extends StatelessWidget {
  const _BatchGroup(
      {super.key,
      required this.index,
      required this.row,
      required this.onRemove});

  final int index;
  final ScanBatchRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: BSizes.sm),
      padding: const EdgeInsets.fromLTRB(
          BSizes.sm, BSizes.xs, BSizes.xs, BSizes.sm),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(BSizes.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Batch ${index + 1}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              IconButton(
                key: Key('scanBatchRemove-$index'),
                tooltip: 'Remove batch',
                visualDensity: VisualDensity.compact,
                icon: Icon(Iconsax.trash,
                    size: BSizes.iconSm, color: theme.colorScheme.error),
                onPressed: onRemove,
              ),
            ],
          ),
          TextFormField(
            key: Key('scanBatchSerial-$index'),
            controller: row.serial,
            decoration: const InputDecoration(labelText: 'Batch / Serial #'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: BSizes.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: Key('scanBatchQty-$index'),
                  controller: row.qty,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return null;
                    final n = ScanBatchesDraft.parseQty(v!);
                    return n == null || n < 0 ? 'Not a number' : null;
                  },
                ),
              ),
              const SizedBox(width: BSizes.sm),
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: Key('scanBatchExpiry-$index'),
                  controller: row.expiry,
                  decoration: const InputDecoration(
                      labelText: 'Expiry', hintText: 'MM/DD/YYYY'),
                  keyboardType: TextInputType.datetime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
