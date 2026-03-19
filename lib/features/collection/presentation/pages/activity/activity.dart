import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import '../bucket/bucket_item_details_screen.dart';
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
                      const Icon(Iconsax.activity, size: 64, color: BColors.darkGrey),
                      const SizedBox(height: BSizes.spaceBtwItems),
                      Text(
                        'No activities yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: BColors.darkGrey),
                      ),
                      const SizedBox(height: BSizes.xs),
                      Text(
                        'Select items from the Collection Bucket\nto start your activity.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BColors.darkGrey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ActivityListTile(
                    title: item.client.name,
                    subtitle:
                        '${item.bankName} • ${item.documentReferences.isNotEmpty ? item.documentReferences.first : '—'}',
                    time: item.assignedAt,
                    status: item.status,
                    statusColor: CollectionStatusColors.colorFor(item.status),
                    icon: CollectionStatusColors.iconFor(item.status),
                    amount: BFormatter.formatPesoCurrency(item.amount),
                    onTap: () async {
                      final result = await Get.to(() => BucketItemDetailsScreen(item: item));
                      if (result != null && result is String) {
                        // Handle the status update from the details page if needed
                        // For example, if 'Payment' was selected, mark as completed
                        if (result == 'Payment') {
                          controller.updateActivityStatus(item.id, CollectionStatusColors.statusCompleted);
                        }
                      }
                    },
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
