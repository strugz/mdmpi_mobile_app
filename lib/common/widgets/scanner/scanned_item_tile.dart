import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/b_simple_chip.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/label_value_text.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

import '../../../base/utils/logger.dart';

/// A single scanned item tile that shows item details and opens the
/// edit modal when tapped. Extracted from `BItemScanner` to reduce
/// widget complexity and improve reuse.
class ScannedItemTile extends StatelessWidget {
  const ScannedItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.controller,
    required this.parentContext,
    required this.dark,
  });

  final InventoryItemModel item;
  final int index;
  final dynamic controller;
  final BuildContext parentContext;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    // Epsilon-check helper to determine if a double is effectively an integer.
    bool qtyIsInteger(double v) => (v % 1).abs() < 1e-9;

    // Determine stable key (prefer id when available)
    final originalId = (() {
      try {
        final v = (item as dynamic).id;
        return v?.toString();
      } catch (_) {
        return null;
      }
    })();
    final originalKey = originalId ?? item.itemCode;
    final originalById = originalId != null;

    return InkWell(
      onTap: () async {
        var itemCodeValue = item.itemCode;
        var descriptionValue = item.description;
        var qtyValue = qtyIsInteger(item.qty)
            ? item.qty.toInt().toString()
            : item.qty.toString();
        var unitValue = item.unit;

        // Helper to robustly parse quantity strings entered by user.
        String normalizeQty(String input) {
          var t = input.trim();
          if (t.isEmpty) return '0';
          // remove spaces
          t = t.replaceAll(' ', '');

          // If both '.' and ',' present, assume commas are thousands separators and remove them.
          if (t.contains('.') && t.contains(',')) {
            t = t.replaceAll(',', '');
          } else if (t.contains(',') && !t.contains('.')) {
            // Ambiguous case: commas may be thousands separators (e.g. 1,000,000)
            // or a decimal separator (e.g. 1234,56). Detect thousands pattern: 1,234 or 12,345,678
            final thousandsPattern = RegExp(r'^\d{1,3}(,\d{3})+$');
            if (thousandsPattern.hasMatch(t)) {
              // Remove thousands separators
              t = t.replaceAll(',', '');
            } else {
              // Treat last comma as decimal separator, remove other commas
              final lastComma = t.lastIndexOf(',');
              if (lastComma != -1) {
                t = t.replaceRange(lastComma, lastComma + 1, '.');
                // Remove any remaining commas (thousands separators)
                t = t.replaceAll(',', '');
              }
            }
          }

          // strip any non-digit/non-dot chars
          t = t.replaceAll(RegExp(r'[^0-9.]'), '');
          // guard against empty
          return t.isEmpty ? '0' : t;
        }

        final formKey = GlobalKey<FormState>();

        // Use a stable root navigator context for overlays to avoid GlobalKey reparenting
        final navContext = Get.context ??
            Get.rootDelegate.navigatorKey.currentContext ??
            parentContext;

        // Prepare an editable copy of batches for the modal (so edits are local until saved)
        final editableBatches = item.batches
            .map((b) => InventoryBatchModel(
                  batchSerial: b.batchSerial,
                  batchQuantity: b.batchQuantity,
                  expiryDate: b.expiryDate,
                ))
            .toList();

        await showModalBottomSheet<void>(
          context: navContext,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (sheetCtx) {
            // Use StatefulBuilder so we can mutate the local editableBatches list
            return StatefulBuilder(builder: (sCtx, setState) {
              return SafeArea(
                minimum: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: BSizes.sm,
                    right: BSizes.sm,
                    top: BSizes.sm,
                    bottom: MediaQuery.of(sCtx).viewInsets.bottom + BSizes.md,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // Item code
                          TextFormField(
                            key: ValueKey(
                                'inventory_item_itemCode_$originalKey'),
                            initialValue: itemCodeValue,
                            textInputAction: TextInputAction.next,
                            decoration:
                                const InputDecoration(labelText: 'Item code'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Item code is required'
                                : null,
                            onSaved: (v) => itemCodeValue = v?.trim() ?? '',
                            onChanged: (v) => itemCodeValue = v.trim(),
                          ),
                          const SizedBox(height: BSizes.sm),

                          // Description
                          TextFormField(
                            key: ValueKey(
                                'inventory_item_description_$originalKey'),
                            initialValue: descriptionValue,
                            textInputAction: TextInputAction.next,
                            decoration:
                                const InputDecoration(labelText: 'Description'),
                            maxLines: 2,
                            onSaved: (v) => descriptionValue = v?.trim() ?? '',
                            onChanged: (v) => descriptionValue = v.trim(),
                          ),
                          const SizedBox(height: BSizes.sm),

                          // Qty + Unit row
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey(
                                      'inventory_item_qty_$originalKey'),
                                  initialValue: qtyValue,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    // allow digits, dot and comma for flexible entry (normalized on save)
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^[0-9.,]*$')),
                                  ],
                                  decoration:
                                      const InputDecoration(labelText: 'Qty'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Quantity is required';
                                    }
                                    final normalized = normalizeQty(v);
                                    final n = double.tryParse(normalized);
                                    if (n == null) {
                                      return 'Enter a valid number';
                                    }
                                    if (n < 0) {
                                      return 'Quantity cannot be negative';
                                    }
                                    return null;
                                  },
                                  onSaved: (v) => qtyValue = v ?? '0',
                                  onChanged: (v) => qtyValue = v,
                                ),
                              ),
                              const SizedBox(width: BSizes.sm),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  key: ValueKey(
                                      'inventory_item_unit_$originalKey'),
                                  initialValue: unitValue,
                                  textInputAction: TextInputAction.done,
                                  decoration:
                                      const InputDecoration(labelText: 'Unit'),
                                  onSaved: (v) => unitValue = v?.trim() ?? '',
                                  onChanged: (v) => unitValue = v.trim(),
                                ),
                              ),
                            ],
                          ),

                          // Editable batches section (serial, qty, expiry) inside modal
                          const SizedBox(height: BSizes.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Batches',
                              style: Theme.of(sCtx).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(height: BSizes.sm),
                          if (editableBatches.isEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No batches',
                                style: Theme.of(sCtx).textTheme.bodySmall,
                              ),
                            ),
                          Column(
                            children:
                                List.generate(editableBatches.length, (i) {
                              final b = editableBatches[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: TextFormField(
                                        key: ValueKey(
                                            'batch_serial_${originalKey}_$i'),
                                        initialValue: b.batchSerial,
                                        decoration: const InputDecoration(
                                            labelText: 'Serial / Batch #'),
                                        onChanged: (v) => setState(() {
                                          editableBatches[i] =
                                              InventoryBatchModel(
                                                  batchSerial: v.trim(),
                                                  batchQuantity:
                                                      editableBatches[i]
                                                          .batchQuantity,
                                                  expiryDate: editableBatches[i]
                                                      .expiryDate);
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: BSizes.sm),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        key: ValueKey(
                                            'batch_qty_${originalKey}_$i'),
                                        initialValue: editableBatches[i]
                                            .batchQuantity
                                            .toString(),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^[0-9.,]*$'))
                                        ],
                                        decoration: const InputDecoration(
                                            labelText: 'Qty'),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Qty required';
                                          }
                                          final normalized = normalizeQty(v);
                                          final n = double.tryParse(normalized);
                                          if (n == null) {
                                            return 'Invalid number';
                                          }
                                          if (n < 0) {
                                            return 'Cannot be negative';
                                          }
                                          return null;
                                        },
                                        onChanged: (v) => setState(() {
                                          final parsed = double.tryParse(
                                                  normalizeQty(v)) ??
                                              0.0;
                                          editableBatches[i] =
                                              InventoryBatchModel(
                                                  batchSerial:
                                                      editableBatches[i]
                                                          .batchSerial,
                                                  batchQuantity: parsed,
                                                  expiryDate: editableBatches[i]
                                                      .expiryDate);
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: BSizes.xs),
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        key: ValueKey(
                                            'batch_expiry_${originalKey}_$i'),
                                        initialValue:
                                            editableBatches[i].expiryDate,
                                        decoration: const InputDecoration(
                                            labelText: 'Expiry'),
                                        onChanged: (v) => setState(() {
                                          editableBatches[i] =
                                              InventoryBatchModel(
                                                  batchSerial:
                                                      editableBatches[i]
                                                          .batchSerial,
                                                  batchQuantity:
                                                      editableBatches[i]
                                                          .batchQuantity,
                                                  expiryDate: v.trim());
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: BSizes.sm),
                                    IconButton(
                                      icon: const Icon(Iconsax.trash,
                                          color: Colors.red),
                                      onPressed: () => setState(() {
                                        editableBatches.removeAt(i);
                                      }),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Iconsax.add_square),
                              label: const Text('Add batch'),
                              onPressed: () => setState(() {
                                editableBatches.add(InventoryBatchModel(
                                    batchSerial: '',
                                    batchQuantity: 0.0,
                                    expiryDate: ''));
                              }),
                            ),
                          ),

                          const SizedBox(height: BSizes.sm),

                          // Actions row
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: ValueKey(
                                      'inventory_item_cancel_$originalKey'),
                                  onPressed: () => Navigator.of(sheetCtx).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: BSizes.sm),
                              IconButton(
                                key: ValueKey(
                                    'inventory_item_delete_$originalKey'),
                                icon: const Icon(Iconsax.trash,
                                    color: Colors.red),
                                onPressed: () async {
                                  final should = await showDialog<bool>(
                                    context: sheetCtx,
                                    useRootNavigator: true,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Confirm delete'),
                                      content: const Text(
                                          'Delete this scanned item?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(dCtx).pop(false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(dCtx).pop(true),
                                            child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (should == true) {
                                    Navigator.of(sheetCtx).pop();
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      try {
                                        controller.removeScannedItem(index);
                                      } catch (_) {}
                                    });
                                  }
                                },
                              ),
                              ElevatedButton(
                                key: ValueKey(
                                    'inventory_item_save_$originalKey'),
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  formKey.currentState!.save();

                                  final parsedQtyText = normalizeQty(qtyValue);
                                  try {
                                    logDebug(
                                        'Saving edited item - parsedQtyText: $parsedQtyText');
                                  } catch (_) {}
                                  final updated = InventoryItemModel(
                                    itemCode: itemCodeValue.trim(),
                                    description: descriptionValue.trim(),
                                    qty: double.tryParse(parsedQtyText) ?? 0.0,
                                    unit: unitValue.trim(),
                                    // Use edited batches from the modal
                                    batches: editableBatches,
                                  );

                                  Navigator.of(sheetCtx).pop();
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    try {
                                      final list = controller
                                          .formState.scannedInventoryItems;
                                      if (index >= 0 && index < list.length) {
                                        final current = list[index];
                                        final matches = identical(
                                                current, item) ||
                                            (current.itemCode == originalKey);
                                        if (matches) {
                                          list[index] = updated;
                                          try {
                                            (list as dynamic).refresh();
                                          } catch (_) {}
                                          Get.snackbar('Item updated',
                                              'Saved changes applied.');
                                          return;
                                        }
                                      }

                                      final didIdentity = controller
                                          .updateScannedItemByIdentity(
                                              item, updated);
                                      try {
                                        logDebug(
                                            'updateScannedItemByIdentity returned: $didIdentity');
                                      } catch (_) {}
                                      if (didIdentity) {
                                        Get.snackbar('Item updated',
                                            'Saved changes applied.');
                                        return;
                                      }

                                      final didKey =
                                          controller.updateScannedItemByKey(
                                              originalKey.toString(), updated,
                                              byId: originalById);
                                      try {
                                        logDebug(
                                            'updateScannedItemByKey returned: $didKey');
                                      } catch (_) {}
                                      if (didKey) {
                                        Get.snackbar('Item updated',
                                            'Saved changes applied.');
                                        return;
                                      }

                                      try {
                                        list.add(updated);
                                        try {
                                          (list as dynamic).refresh();
                                        } catch (_) {}
                                        Get.snackbar('Item updated',
                                            'Saved changes applied (fallback appended).');
                                      } catch (_) {
                                        Get.snackbar('Update failed',
                                            'Unable to update scanned item');
                                      }
                                    } catch (e) {
                                      try {
                                        logDebug(
                                            'Error during post-save update: $e');
                                      } catch (_) {}
                                      Get.snackbar('Update failed',
                                          'Unable to update scanned item');
                                    }
                                  });
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),

                          const SizedBox(height: BSizes.md),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
      child: BRoundedContainer(
        backgroundColor: dark
            ? BColors.darkerGrey.withAlpha((0.18 * 255).toInt())
            : BColors.light,
        radius: BSizes.cardRadiusSm,
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.sm, vertical: BSizes.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemCode,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: BSizes.sm),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BSizes.xs),

                  // Use shared label-value widget for consistency
                  BLabelValueText(
                    label: 'Qty',
                    value:
                        '${qtyIsInteger(item.qty) ? item.qty.toInt() : item.qty}  •  ${item.unit}',
                    smallSize: true,
                    showLabel: true,
                    padding: EdgeInsets.zero,
                    textColor: dark ? BColors.light : BColors.darkGrey,
                  ),

                  // Inline batches summary (show up to 2 batches inline, then +N)
                  if (item.batches.isNotEmpty) ...[
                    const SizedBox(height: BSizes.sm),
                    Wrap(
                      spacing: BSizes.sm,
                      runSpacing: BSizes.xs,
                      children: [
                        ...item.batches.take(2).map((b) {
                          final txt =
                              '${b.batchSerial} • ${b.batchQuantity}${b.expiryDate.isNotEmpty ? ' • ${b.expiryDate}' : ''}';
                          return BSimpleChip(label: txt);
                        }),
                        if (item.batches.length > 2)
                          BSimpleChip(
                              label: '+${item.batches.length - 2} more'),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // quick delete (keeps original UX)
            IconButton(
              key: ValueKey('inventory_item_quick_delete_${item.itemCode}'),
              onPressed: () => controller.removeScannedItem(index),
              icon: Icon(Iconsax.close_circle,
                  size: 20, color: dark ? BColors.light : BColors.darkGrey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
