import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

/// Widget that renders the batch details for an inventory item.
///
/// Shows a small header with a layers icon and count, a compact column header
/// row (Serial / Qty / Expiry) and a list of [InventoryBatchRow].
class InventoryBatchDetails extends StatelessWidget {
  const InventoryBatchDetails({
    super.key,
    required this.batches,
  });

  final List<InventoryBatchModel> batches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerLabelStyle = theme.textTheme.labelSmall
        ?.copyWith(color: BColors.textSecondary, fontSize: 12);
    final valueStyle = theme.textTheme.bodySmall
        ?.copyWith(color: BColors.textPrimary, fontSize: 11);

    if (batches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('No batch/serial details',
              style: theme.textTheme.bodySmall),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, size: 16, color: BColors.primary),
              const SizedBox(width: 8),
              Text('${batches.length} batch(es)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: BColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),

          // Column headers aligned with batch columns
          Padding(
            padding: const EdgeInsets.only(right: 4.0, bottom: 6.0),
            child: Row(
              children: [
                Expanded(flex: 6, child: Text('Serial', style: headerLabelStyle)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Qty', style: headerLabelStyle),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Expiry', style: headerLabelStyle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Column(
            children: List<Widget>.generate(batches.length, (i) {
              final b = batches[i];
              return Column(
                children: [
                  InventoryBatchRow(batch: b, valueStyle: valueStyle),
                  if (i < batches.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Single batch row widget used inside [InventoryBatchDetails].
class InventoryBatchRow extends StatelessWidget {
  const InventoryBatchRow({
    super.key,
    required this.batch,
    this.valueStyle,
  });

  final InventoryBatchModel batch;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.batchSerial.isNotEmpty ? batch.batchSerial : '(no serial)',
                    style: valueStyle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(BFormatter.formatIntegerNoDecimal(batch.batchQuantity), style: valueStyle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(batch.expiryDate.isNotEmpty ? batch.expiryDate : '-', style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

