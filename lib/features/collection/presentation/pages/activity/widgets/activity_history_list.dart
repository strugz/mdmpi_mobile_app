import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({
    super.key,
    required this.history,
    this.accountNames,
    this.invoiceIds,
    this.items,
  });

  final List<CollectionHistoryModel> history;
  
  /// Optional: Map of history index to account name (for global lists)
  final Map<int, String>? accountNames;
  
  /// Optional: Map of history index to invoice ID (for global lists)
  final Map<int, String?>? invoiceIds;

  /// Optional: Map of history index to full invoice item
  final Map<int, CollectionItemModel?>? items;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: BSizes.lg),
          child: Text('No history available.'),
        ),
      );
    }

    // The history is already sorted newest-first by the controller.
    final List<CollectionHistoryModel> displayList = history;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        return _ActivityHistoryCard(
          history: displayList[index],
          accountName: accountNames?[index],
          invoiceId: invoiceIds?[index],
          item: items?[index],
        );
      },
    );
  }
}

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({
    required this.history,
    this.accountName,
    this.invoiceId,
    this.item,
  });

  final CollectionHistoryModel history;
  final String? accountName;
  final String? invoiceId;
  final CollectionItemModel? item;

  void _showDetail(BuildContext context, String collectorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: BColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: BSizes.md),
                decoration: BoxDecoration(
                  color: BColors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activity Details', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: BSizes.sm),

            if (accountName != null || invoiceId != null || item != null) ...[
              Text(
                accountName ?? item?.client.name ?? 'Unknown Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: BColors.primary),
              ),
              if (invoiceId != null || item != null)
                Text('Invoice #${invoiceId ?? item?.id}', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: BSizes.md),
            ],

            if (item != null) ...[
              Wrap(
                spacing: BSizes.sm,
                runSpacing: BSizes.sm,
                children: [
                  _buildInfoTile(context, 'Total Amount', BFormatter.formatPesoCurrency(item!.toBeCollected + item!.totalCollected), Iconsax.money),
                  _buildInfoTile(context, 'Current Balance', BFormatter.formatPesoCurrency(item!.toBeCollected), Iconsax.wallet_money, valueColor: BColors.primary),
                  _buildInfoTile(context, 'Due Date', item!.dueDate, Iconsax.calendar, valueColor: item!.isOverdue ? BColors.error : null),
                  if (item!.documentReferences.isNotEmpty)
                    _buildInfoTile(context, 'References', item!.documentReferences.join(', '), Iconsax.document_text),
                ],
              ),
              const Divider(height: BSizes.lg),
            ],

            Wrap(
              spacing: BSizes.sm,
              runSpacing: BSizes.sm,
              children: [
                _buildInfoTile(context, 'Date', history.date, Iconsax.calendar),
                _buildInfoTile(context, 'Collector', collectorName, Iconsax.user),
                _buildInfoTile(
                  context, 
                  'Status', 
                  history.status, 
                  Iconsax.activity,
                  isBadge: true,
                ),
                
                if (history.totalCollected > 0)
                  _buildInfoTile(
                    context, 
                    'Amount Collected', 
                    BFormatter.formatPesoCurrency(history.totalCollected),
                    Iconsax.wallet_money,
                    valueColor: BColors.success
                  ),

                if (history.bankName != null && history.bankName!.isNotEmpty)
                  _buildInfoTile(context, 'Bank', history.bankName!, Iconsax.bank),

                if (history.checkNumber != null && history.checkNumber!.isNotEmpty)
                  _buildInfoTile(context, 'Check Number', history.checkNumber!, Iconsax.card_edit),

                if (history.checkDate != null && history.checkDate!.isNotEmpty)
                  _buildInfoTile(context, 'Check Date', history.checkDate!, Iconsax.calendar_1),
              ],
            ),

            const SizedBox(height: BSizes.md),
            Text('Remarks', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: BSizes.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BSizes.md),
              decoration: BoxDecoration(
                color: BColors.lightGrey,
                borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
              ),
              child: Text(
                history.remarks.isEmpty || history.remarks == 'No remarks' 
                    ? 'No additional remarks provided.' 
                    : history.remarks,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    {bool isBadge = false, Color? valueColor}
  ) {
    final width = (MediaQuery.of(context).size.width - (BSizes.defaultSpace * 2) - BSizes.sm) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(BSizes.sm),
      decoration: BoxDecoration(
        color: BColors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        border: Border.all(color: BColors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BColors.primary),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                if (isBadge)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _ActivityHistoryBadge(status: value),
                  )
                else
                  Text(
                    value, 
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                      fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    String displayCollectorName = history.collectorName;
    if (displayCollectorName == 'You') {
      displayCollectorName = UserController.instance.user.value.initials;
    }

    final isOverdue = item?.isOverdue ?? false;
    final daysPast = item?.daysPastDue ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      child: InkWell(
        onTap: () => _showDetail(context, displayCollectorName),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsets.all(BSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header: Invoice ID and BP Code + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoiceId != null || item != null 
                              ? 'Invoice #${invoiceId ?? item?.id}' 
                              : (accountName ?? 'Account Activity'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item != null)
                          Text(
                            'BP: ${item!.bpCode}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: BColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _ActivityHistoryBadge(status: history.status),
                ],
              ),
              const SizedBox(height: BSizes.sm),

              /// Body Row 1: Posted Date + Amount Collected
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Iconsax.calendar, size: 14, color: BColors.darkGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Posted: ${item?.postingDate ?? 'N/A'}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: BColors.darkGrey,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (history.totalCollected > 0)
                    Text(
                      BFormatter.formatPesoCurrency(history.totalCollected),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: BSizes.xs),

              /// Body Row 2: Due Date + Overdue Tag + Collector Name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Iconsax.timer, size: 14, color: isOverdue ? BColors.error : BColors.darkGrey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Due: ${item?.dueDate ?? 'N/A'}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isOverdue ? BColors.error : BColors.darkGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: BSizes.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: BColors.error,
                              borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
                            ),
                            child: Text(
                              BFormatter.formatDaysOverdue(daysPast),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: BColors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    displayCollectorName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BColors.darkGrey, fontSize: 10),
                  ),
                ],
              ),
              const Divider(height: BSizes.md),

              /// Footer: Timestamp and Remarks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    history.date,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
                  if (history.remarks.isNotEmpty && history.remarks != 'No remarks')
                    Expanded(
                      child: Text(
                        '  |  ${history.remarks}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                          color: BColors.darkerGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityHistoryBadge extends StatelessWidget {
  const _ActivityHistoryBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();
    final (bg, _) = CollectionStatusColors.colorsForAuto(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        status,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
