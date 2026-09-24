import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

class InvoiceDetailsModal extends StatelessWidget {
  const InvoiceDetailsModal({super.key, required this.item});

  final CollectionItemModel item;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: BCollectionColors.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        padding: EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace,
            BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom),
        // One scrolling list, on the sheet's own controller so dragging and
        // scrolling hand off. The info grid used to sit fixed above an
        // Expanded history list; at a large font the fixed part alone was
        // taller than the sheet and it overflowed at the bottom.
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            /// Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: BSizes.md),
                decoration: BoxDecoration(
                  color: BCollectionColors.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Invoice Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: BSizes.sm),

            Text(
              item.client.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: BCollectionColors.primary),
            ),
            Text('Invoice #${item.id}',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: BSizes.md),

            /// Info Grid
            Wrap(
              spacing: BSizes.sm,
              runSpacing: BSizes.sm,
              children: [
                _buildInfoTile(
                    context,
                    'Amount Due',
                    BFormatter.formatPesoCurrency(item.toBeCollected),
                    Iconsax.money_send,
                    valueColor: BCollectionColors.primary),
                _buildInfoTile(
                    context,
                    'Collected',
                    BFormatter.formatPesoCurrency(item.totalCollected),
                    Iconsax.wallet_money,
                    valueColor: BCollectionColors.success),
                _buildInfoTile(
                    context, 'Due Date', item.dueDate, Iconsax.calendar,
                    valueColor:
                        item.isOverdue ? BCollectionColors.danger : null),
                _buildInfoTile(
                    context, 'Account Name', item.client.name, Iconsax.user,
                    valueColor: BCollectionColors.primary),
                // The customer's P.O. (SAP BP Ref. No.); hidden when SAP had none.
                if (item.hasPoNumber)
                  _buildInfoTile(context, 'P.O. Number', item.poNumber.trim(),
                      Iconsax.receipt_item),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: BSizes.md),
              child: Divider(),
            ),

            Text('Activity History',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.sm),

            if (item.history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: BSizes.lg),
                child:
                    Center(child: Text('No history found for this invoice.')),
              )
            else
              // Newest first.
              for (final (index, history) in item.history.reversed.indexed) ...[
                if (index > 0) const SizedBox(height: BSizes.md),
                Container(
                  padding: const EdgeInsets.all(BSizes.md),
                  decoration: BoxDecoration(
                    color: BCollectionColors.background,
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                    border: Border.all(
                        color:
                            BCollectionColors.outline.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap: a long status drops under the date
                      // instead of overrunning the entry.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: BSizes.sm,
                        runSpacing: BSizes.xs,
                        children: [
                          Text(history.date,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          _buildStatusBadge(context, history.status),
                        ],
                      ),
                      const SizedBox(height: BSizes.sm),
                      Wrap(
                        spacing: BSizes.xs,
                        runSpacing: BSizes.xs,
                        children: [
                          _buildCompactInfo(context, 'Collector',
                              history.collectorName, Iconsax.user),
                          if (history.totalCollected > 0)
                            _buildCompactInfo(
                                context,
                                'Collected',
                                BFormatter.formatPesoCurrency(
                                    history.totalCollected),
                                Iconsax.wallet_money,
                                valueColor: BCollectionColors.success),
                          if (history.bankName != null &&
                              history.bankName!.isNotEmpty)
                            _buildCompactInfo(context, 'Bank',
                                history.bankName!, Iconsax.bank),
                          if (history.checkNumber != null &&
                              history.checkNumber!.isNotEmpty)
                            _buildCompactInfo(context, 'Check #',
                                history.checkNumber!, Iconsax.card_edit),
                          if (history.checkDate != null &&
                              history.checkDate!.isNotEmpty)
                            _buildCompactInfo(context, 'Check Date',
                                history.checkDate!, Iconsax.calendar_1),
                        ],
                      ),
                      const SizedBox(height: BSizes.xs),
                      Text('Remarks:',
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(
                        history.remarks.isEmpty ||
                                history.remarks == 'No remarks'
                            ? 'No remarks'
                            : history.remarks,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            const SizedBox(height: BSizes.md),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, String label, String value, IconData icon,
      {bool isBadge = false, Color? valueColor}) {
    final width = (MediaQuery.of(context).size.width -
            (BSizes.defaultSpace * 2) -
            BSizes.sm) /
        2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(BSizes.sm),
      decoration: BoxDecoration(
        color: BCollectionColors.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        border:
            Border.all(color: BCollectionColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BCollectionColors.primary),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                if (isBadge)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _buildStatusBadge(context, value),
                  )
                else
                  Text(
                    value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(
      BuildContext context, String label, String value, IconData icon,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BCollectionColors.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
        border: Border.all(
            color: BCollectionColors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: BCollectionColors.inkMuted),
          const SizedBox(width: 4),
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: BCollectionColors.inkMuted)),
          // Flexible: a long bank or collector name ends in "…" inside its
          // chip rather than pushing the chip past the sheet's edge.
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? BCollectionColors.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final (bg, _) = CollectionStatusColors.colorsForAuto(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        status,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: bg, fontWeight: FontWeight.bold),
      ),
    );
  }
}
