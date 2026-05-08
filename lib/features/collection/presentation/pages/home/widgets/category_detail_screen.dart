import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_list_tile.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/due_date_helper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
// ...existing code...

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
          // Core and Outcomes categories removed — their filters and summary cards were removed.
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
                // 'Core' and 'Outcomes' cases removed.
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
