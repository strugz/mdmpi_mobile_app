import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: BSizes.spaceBtwItems),

          /// Filter chips (Defaulting to all simple statuses)
          ActivityFilterChips(
            onFilterChanged: (filter) {
              controller.setActivityFilter(filter);
            },
          ),

          const SizedBox(height: BSizes.spaceBtwSections),

          /// Activity History list
          Expanded(
            child: Obx(() {
              final items = controller.filteredActivityItems;

              if (items.isEmpty) {
                return const Center(
                  child: Text('No activities found for this filter.'),
                );
              }

              // Flatten history from the items in this category
              final allHistory = items.expand((item) => item.history).toList();

              if (allHistory.isEmpty) {
                return const Center(
                  child: Text('No history found for these items.'),
                );
              }

              // Sort newest first
              allHistory.sort((a, b) => b.date.compareTo(a.date));

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                child: ActivityHistoryList(history: allHistory),
              );
            }),
          ),
        ],
      ),
    );
  }
}
