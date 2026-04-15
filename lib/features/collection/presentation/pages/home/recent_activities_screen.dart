import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';

class RecentActivitiesScreen extends StatelessWidget {
  const RecentActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activities'),
      ),
      body: Column(
        children: [
          const SizedBox(height: BSizes.spaceBtwItems),
          
          /// Filter chips
          ActivityFilterChips(
            onFilterChanged: (filter) {
              controller.setActivityFilter(filter);
            },
          ),

          const SizedBox(height: BSizes.spaceBtwItems),

          /// Recent Activities List
          Expanded(
            child: Obx(() {
              final items = controller.filteredActivityItems;
              
              // Flatten history from the filtered items
              final allHistory = items.expand((item) => item.history).toList();

              if (allHistory.isEmpty) {
                return const Center(child: Text('No recent activities found.'));
              }

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
