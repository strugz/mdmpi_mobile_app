import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_list_tile.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/activity_detail_screen.dart';

import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({
    super.key,
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

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
          if (title == 'Core') ...[
            const SizedBox(height: BSizes.spaceBtwItems),
            ActivityFilterChips(
              filters: const ['All', 'Pending', 'On-going'],
              activeColor: color,
              onFilterChanged: (filter) => selectedFilter.value = filter,
            ),
          ] else if (title == 'Outcomes') ...[
            const SizedBox(height: BSizes.spaceBtwItems),
            ActivityFilterChips(
              filters: const [
                'All',
                'Collected',
                'Partially Collected',
                'Failed',
                'Customer Unavailable',
                'Refused to Pay'
              ],
              activeColor: color,
              onFilterChanged: (filter) => selectedFilter.value = filter,
            ),
          ],
          const SizedBox(height: BSizes.spaceBtwItems),
          Expanded(
            child: Obx(() {
              List<CollectionItemModel> items = [];

              switch (title) {
                case 'Core':
                  items = controller.coreItems;
                  if (selectedFilter.value == 'Pending') {
                    items = items.where((i) => i.status == CollectionStatusColors.statusPending).toList();
                  } else if (selectedFilter.value == 'On-going') {
                    items = items.where((i) => i.status == CollectionStatusColors.statusOngoing).toList();
                  }
                  break;
                case 'Outcomes':
                  items = controller.outcomeItems;
                  if (selectedFilter.value != 'All') {
                    items = items.where((i) => i.lastOutcome == selectedFilter.value).toList();
                  }
                  break;
                case 'Completed':
                  items = controller.completedItems;
                  break;
                case 'Due Date':
                  items = controller.overdueItems;
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
                    onTap: null, // Cards are not clickable in this screen
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
