import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_filter_chips.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_list_tile.dart';

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

  List<String> _getFiltersForCategory(String category) {
    switch (category) {
      case 'Core Status':
        return [
          'All',
          CollectionStatusColors.statusUnassigned,
          CollectionStatusColors.statusOngoing,
        ];
      case 'Delays':
        return [
          'All',
          CollectionStatusColors.statusRescheduled,
          CollectionStatusColors.statusBehindSchedule,
        ];
      case 'Completed':
        return [
          'All',
          CollectionStatusColors.statusFullyCollected,
          CollectionStatusColors.statusPartiallyCollected,
          CollectionStatusColors.statusFailedCollection,
          CollectionStatusColors.statusCustomerUnavailable,
          CollectionStatusColors.statusRefusedToPay,
        ];
      case 'Administrative':
        return [
          'All',
          CollectionStatusColors.statusCancelled,
          CollectionStatusColors.statusOnHold,
          CollectionStatusColors.statusForVerification,
        ];
      default:
        return ['All'];
    }
  }

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

          /// Filter chips
          ActivityFilterChips(
            filters: _getFiltersForCategory(title),
            onFilterChanged: (filter) {
              controller.setActivityFilter(filter);
            },
          ),

          const SizedBox(height: BSizes.spaceBtwSections),

          /// Activity list
          Expanded(
            child: Obx(() {
              final items = controller.filteredActivityItems;

              if (items.isEmpty) {
                return const Center(
                  child: Text('No activities found for this filter.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
                itemBuilder: (context, index) {
                  return ActivityListTile(item: items[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
