import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

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
              // Get global history from controller
              final recentItems = controller.allRecentHistory;
              
              if (recentItems.isEmpty) {
                return const Center(child: Text('No recent activities found.'));
              }

              // Apply status filter if not "All"
              final filteredItems = controller.activityFilter.value == 'All'
                  ? recentItems
                  : recentItems.where((item) => item['history'].status == controller.activityFilter.value).toList();

              if (filteredItems.isEmpty) {
                return const Center(child: Text('No activities match this filter.'));
              }

              final historyList = filteredItems.map((e) => e['history'] as CollectionHistoryModel).toList();
              final accountNames = { for (var i = 0; i < filteredItems.length; i++) i : filteredItems[i]['accountName'].toString() };
              final invoiceIds = { for (var i = 0; i < filteredItems.length; i++) i : filteredItems[i]['invoiceId']?.toString() };
              final items = { for (var i = 0; i < filteredItems.length; i++) i : filteredItems[i]['item'] as CollectionItemModel? };

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                child: ActivityHistoryList(
                  history: historyList,
                  accountNames: accountNames,
                  invoiceIds: invoiceIds,
                  items: items,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
