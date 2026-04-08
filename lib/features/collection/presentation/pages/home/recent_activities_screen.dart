import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/activity_detail_screen.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_list_tile.dart';

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

              if (items.isEmpty) {
                return const Center(child: Text('No recent activities found.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ActivityListTile(
                    item: item,
                    onTap: () => Get.to(() => ActivityDetailScreen(item: item)),
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
