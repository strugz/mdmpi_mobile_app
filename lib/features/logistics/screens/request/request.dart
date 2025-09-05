import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/common/widgets/appbar/appbar.dart';
import 'package:mdmpi_mobile_app/common/widgets/dropdown/filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/b_filter_dropdown.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/b_floating_button.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request/widgets/b_list.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

import '../../controllers/request_controller.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();
    final userController = Get.find<UserController>();

    return Scaffold(
      appBar: BAppBar(
        title:
            Text('Request', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          // Obx widget rebuilds when useLocalStorage changes
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                children: [
                  Text(requestController.useLocalStorage.value
                      ? 'Server'
                      : 'Local'),
                  Switch(
                    value: requestController.useLocalStorage.value,
                    onChanged: (value) {
                      // Call the controller method to update the state
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
          const BFilterDropdown(),
          const SizedBox(height: BSizes.spaceBtwItems),
          FilterDropdown(
              selectedFilter:
                  requestController.filterManager.selectedStatusFilter,
              filterValues: RequestStatusFilter.values,
              getDisplayName: (filter) => filter.displayName,
              onFilterChanged: (filter) {
                requestController.selectStatusFilter(filter);
              }),
          const SizedBox(
              height: BSizes.spaceBtwSections / 3), // Added some spacing
          const BList()
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
  }
}
