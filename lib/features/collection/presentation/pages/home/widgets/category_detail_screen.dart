import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_list_tile.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/due_date_helper.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  void _showInvoiceDetail(BuildContext context, CollectionItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: BColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
          ),
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Invoice Details', style: Theme.of(context).textTheme.headlineSmall),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: BColors.primary),
              ),
              Text('Invoice #${item.id}', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: BSizes.md),

              _buildDetailRow(context, 'Total Amount Due', BFormatter.formatPesoCurrency(item.toBeCollected), valueColor: BColors.primary, icon: Iconsax.money_send),
              _buildDetailRow(context, 'Total Collected', BFormatter.formatPesoCurrency(item.totalCollected), valueColor: BColors.success, icon: Iconsax.wallet_money),
              _buildDetailRow(context, 'Due Date', item.dueDate, valueColor: item.isOverdue ? BColors.error : null, icon: Iconsax.calendar),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: BSizes.md),
                child: Divider(),
              ),
              
              Text('Activity History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: BSizes.sm),

              Expanded(
                child: item.history.isEmpty
                    ? const Center(child: Text('No history found for this invoice.'))
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: item.history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: BSizes.md),
                        itemBuilder: (context, index) {
                          // Show newest history first
                          final history = item.history.reversed.toList()[index];
                          return Container(
                            padding: const EdgeInsets.all(BSizes.md),
                            decoration: BoxDecoration(
                              color: BColors.lightGrey,
                              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                              border: Border.all(color: BColors.grey.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(history.date, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                                    _buildStatusBadge(context, history.status),
                                  ],
                                ),
                                const SizedBox(height: BSizes.sm),
                                
                                if (history.purposeOfVisit != null)
                                  _buildHistoryItem(context, 'Purpose', history.purposeOfVisit!, Iconsax.info_circle),
                                
                                _buildHistoryItem(context, 'Collector', history.collectorName, Iconsax.user),
                                
                                if (history.totalCollected > 0)
                                  _buildHistoryItem(
                                    context, 
                                    'Collected', 
                                    BFormatter.formatPesoCurrency(history.totalCollected),
                                    Iconsax.wallet_money,
                                    valueColor: BColors.success
                                  ),

                                if (history.bankName != null && history.bankName!.isNotEmpty)
                                  _buildHistoryItem(context, 'Bank', history.bankName!, Iconsax.bank),

                                if (history.checkNumber != null && history.checkNumber!.isNotEmpty)
                                  _buildHistoryItem(context, 'Check #', history.checkNumber!, Iconsax.card_edit),

                                if (history.checkDate != null && history.checkDate!.isNotEmpty)
                                  _buildHistoryItem(context, 'Check Date', history.checkDate!, Iconsax.calendar_1),

                                const SizedBox(height: BSizes.xs),
                                Text('Remarks:', style: Theme.of(context).textTheme.labelSmall),
                                Text(
                                  history.remarks.isEmpty || history.remarks == 'No remarks' 
                                      ? 'No remarks' 
                                      : history.remarks,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: BSizes.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: BColors.darkGrey),
          const SizedBox(width: 8),
          Text('$label: ', style: Theme.of(context).textTheme.labelSmall),
          Expanded(
            child: Text(
              value, 
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, 
    {bool isBadge = false, Color? valueColor, IconData? icon}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: BColors.darkGrey),
            const SizedBox(width: BSizes.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                if (isBadge)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildStatusBadge(context, value),
                  )
                else
                  Text(
                    value, 
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                    )
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
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

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    final RxString selectedFilter = 'All'.obs;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: BSizes.spaceBtwItems),
          if (title == 'Due Date') ...[
            ActivityFilterChips(
              filters: DueDateHelper.labelsWithAll,
              activeColor: color,
              onFilterChanged: (filter) => selectedFilter.value = filter,
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
          ],
          Expanded(
            child: Obx(() {
              List<CollectionItemModel> items = [];

              switch (title) {
                case 'Completed':
                  items = controller.completedItems;
                  break;
                case 'Due Date':
                  items = controller.overdueItems;
                  if (selectedFilter.value != 'All') {
                    final bucket = DueDateHelper.fromLabel(selectedFilter.value)!;
                    items = items.where((i) => DueDateHelper.inBucket(i.daysPastDue, bucket)).toList();
                  }
                  break;
                default:
                  items = [];
              }

              if (items.isEmpty) {
                return const Center(
                  child: Text('No items found for this category.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(BSizes.defaultSpace),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ActivityListTile(
                    item: item,
                    onTap: () => _showInvoiceDetail(context, item),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
