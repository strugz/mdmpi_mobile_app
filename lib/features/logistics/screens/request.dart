import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pull_out_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/pick_up_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/widgets/b_floating_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/standard_delivery/standard_delivery_list.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pull_out_return_pick_up/pull_out_return_pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/pick_up/pick_up_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pull_out_filter_manager.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/pick_up_filter_manager.dart';

import '../controllers/standard_delivery_controller.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();
    final userController = Get.find<UserController>();
    final pullOutController = Get.find<PullOutController>();
    final pickUpController = Get.find<PickUpController>();

    return DefaultTabController(
      length: 3,
      child: Builder(builder: (context) {
        final TabController tabController = DefaultTabController.of(context);

        return Scaffold(
          appBar: BAppBar(
            title: Text('Request', style: Theme.of(context).textTheme.headlineMedium),
            actions: [
              Obx(() {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    children: [
                      Text(requestController.useLocalStorage.value ? 'Server' : 'Local'),
                      Switch(
                        value: requestController.useLocalStorage.value,
                        onChanged: (value) {
                          requestController.toggleStoragePreference(value);
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          body: Column(
            children: [
              // Top filter area: switches based on active tab using AnimatedBuilder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace, vertical: 8),
                child: AnimatedBuilder(
                  animation: tabController,
                  builder: (context, _) {
                    final currentIndex = tabController.index;
                    if (currentIndex == 0) {
                      // Standard Delivery filters
                      return Column(
                        children: [
                          const BFilterDropdown(),
                          const SizedBox(height: BSizes.spaceBtwItems),
                          FilterDropdown(
                            selectedFilter: requestController.filterManager.selectedStatusFilter,
                            filterValues: RequestStatusFilter.values,
                            getDisplayName: (filter) => filter.displayName,
                            onFilterChanged: (filter) {
                              requestController.selectStatusFilter(filter);
                            },
                          ),
                        ],
                      );
                    } else if (currentIndex == 1) {
                      // Pull-out filters
                      return Column(
                        children: [
                          // Date filter for Pull-out using same RequestFilter enum
                          FilterDropdown<RequestFilter>(
                            selectedFilter: pullOutController.filterManager.selectedFilter,
                            filterValues: RequestFilter.values,
                            getDisplayName: (f) => f.displayName,
                            onFilterChanged: (f) {
                              pullOutController.selectDateFilter(f);
                            },
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),
                          // Status filter for Pull-out
                          FilterDropdown<PullOutStatusFilter>(
                            selectedFilter: pullOutController.filterManager.selectedStatusFilter,
                            filterValues: PullOutStatusFilter.values,
                            getDisplayName: (f) => f.displayName,
                            onFilterChanged: (f) {
                              pullOutController.selectStatusFilter(f);
                            },
                          ),
                        ],
                      );
                    } else {
                      // Pick-Up filters
                      return Column(
                        children: [
                          // Date filter for Pick-up using same RequestFilter enum
                          FilterDropdown<RequestFilter>(
                            selectedFilter: pickUpController.filterManager.selectedFilter,
                            filterValues: RequestFilter.values,
                            getDisplayName: (f) => f.displayName,
                            onFilterChanged: (f) {
                              pickUpController.selectDateFilter(f);
                            },
                          ),
                          const SizedBox(height: BSizes.spaceBtwItems),
                          // Status filter for Pick-up
                          FilterDropdown<PickUpStatusFilter>(
                            selectedFilter: pickUpController.filterManager.selectedStatusFilter,
                            filterValues: PickUpStatusFilter.values,
                            getDisplayName: (f) => f.displayName,
                            onFilterChanged: (f) {
                              pickUpController.selectStatusFilter(f);
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),

              TabBar(
                controller: tabController,
                isScrollable: false,
                tabs: const [
                  Tab(text: 'Standard Delivery'),
                  Tab(text: 'Pull-out'),
                  Tab(text: 'Pick-Up'),
                ],
              ),
              const SizedBox(height: BSizes.spaceBtwItems),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Standard Delivery tab: only the list (filters are above)
                    Column(
                      children: const [
                        SizedBox(height: 8),
                        BList(),
                      ],
                    ),
                    // Pull-out tab: only the list (filters are above)
                    Column(
                      children: const [
                        PullOutReturnPickUpList(),
                      ],
                    ),
                    // Pick-Up tab: only the list (filters are above)
                    Column(
                      children: const [
                        PickUpList(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Obx(() {
            if (!userController.user.value.role.contains(BTexts.roleRequest)) {
              return Container();
            } else {
              return const BFloatingButton();
            }
          }),
        );
      }),
    );
  }
}
