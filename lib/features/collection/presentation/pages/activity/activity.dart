import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

import 'widgets/activity_filter_chips.dart';
import 'widgets/activity_list_tile.dart';

/// Collection Activity Screen
///
/// Shows collection items the user has claimed from the Collection Bucket.
/// Items appear here after being selected in the bucket screen.
class CollectionActivityScreen extends StatelessWidget {
  const CollectionActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CollectionActivityController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement search
            },
            icon: const Icon(Iconsax.search_normal),
          ),
        ],
      ),
      body: Column(
        children: [
          /// Filter chips
          ActivityFilterChips(
            onFilterChanged: (filter) => controller.setActivityFilter(filter),
          ),

          const SizedBox(height: BSizes.spaceBtwItems),

          /// Activity list — driven by controller
          Expanded(
            child: Obx(() {
              final items = controller.filteredActivityItems;

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.activity,
                          size: 64, color: BColors.darkGrey),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      Text(
                        'No activities yet',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: BColors.darkGrey),
                      ),
                      const SizedBox(height: BSizes.xs),
                      Text(
                        'Select items from the Collection Bucket\nto start your activity.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: BColors.darkGrey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.defaultSpace),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: BSizes.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ActivityListTile(
                    title: item.client.name,
                    subtitle:
                        '${item.bankName} • ${item.documentReferences.isNotEmpty ? item.documentReferences.first : '—'}',
                    time: item.assignedAt,
                    status: item.status,
                    statusColor: _statusColor(item.status),
                    icon: _statusIcon(item.status),
                    amount: '₱${_formatAmount(item.amount)}',
                    onTap: () => _showItemDetails(context, item, controller),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Map status text to a colour.
  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return BColors.success;
      case 'Overdue':
        return BColors.error;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  /// Map status text to an icon.
  IconData _statusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Iconsax.tick_circle;
      case 'Overdue':
        return Iconsax.warning_2;
      case 'Pending':
      default:
        return Iconsax.clock;
    }
  }

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  /// Bottom sheet showing full item details with a status-update action.
  void _showItemDetails(
    BuildContext context,
    CollectionItemModel item,
    CollectionActivityController controller,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BSizes.cardRadiusLg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.client.name,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: BSizes.xs),
            Text(item.client.address,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: BColors.darkGrey)),
            const SizedBox(height: BSizes.spaceBtwItems),
            _detailRow(context, 'Bank', item.bankName),
            _detailRow(context, 'Documents',
                item.documentReferences.join(', ')),
            _detailRow(context, 'Amount',
                '₱${_formatAmount(item.amount)}'),
            _detailRow(context, 'Document Date', item.documentDate),
            if (item.remarks.isNotEmpty)
              _detailRow(context, 'Remarks', item.remarks),
            _detailRow(context, 'Status', item.status),
            const SizedBox(height: BSizes.spaceBtwSections),
            if (item.status == 'Pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    controller.updateActivityStatus(item.id, 'Completed');
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Iconsax.tick_circle),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BColors.success,
                    foregroundColor: BColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: BColors.darkGrey)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}


