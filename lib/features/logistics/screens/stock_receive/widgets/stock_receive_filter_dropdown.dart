import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/stock_receive_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_filter_manager.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

/// Date filter dropdown widget for Stock Receive requests.
///
/// Displays a dropdown with date filter options (Today, Yesterday, Tomorrow, etc.)
/// and applies the selected filter to the Stock Receive controller.
class StockReceiveFilterDropdown extends StatelessWidget {
  const StockReceiveFilterDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<StockReceiveController>();

    return BRoundedContainer(
      radius: 18,
      height: 50,
      backgroundColor: dark ? BColors.darkerGrey : BColors.white,
      child: Obx(
        () => DropdownButtonFormField<RequestFilter>(
          initialValue: controller.filterManager.selectedFilter.value,
          onChanged: (RequestFilter? newValue) {
            if (newValue != null) {
              controller.selectDateFilter(newValue);
            }
          },
          dropdownColor: dark ? BColors.darkerGrey : BColors.white,
          decoration: const InputDecoration(
            prefixIcon: Icon(Iconsax.sort),
          ),
          items: RequestFilter.values
              .map(
                (RequestFilter option) => DropdownMenuItem<RequestFilter>(
              value: option,
              child: Text(
                option.displayName,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall!
                    .apply(color: dark ? BColors.light : BColors.dark),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

