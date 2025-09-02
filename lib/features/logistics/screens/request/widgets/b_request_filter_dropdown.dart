import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

class BRequestFilterDropdown extends StatelessWidget {
  const BRequestFilterDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<RequestController>();
    return BRoundedContainer(
      radius: 18,
      height: 50,
      backgroundColor: dark ? BColors.darkerGrey : BColors.white,
      child: Obx(
        () => DropdownButtonFormField<RequestFilter>(
          value:
          controller.filterManager.selectedFilter.value, // Now uses the enum value directly
          onChanged: (RequestFilter? newValue) {
            // Changed to RequestFilter?
            if (newValue != null) {
              controller.selectFilter(newValue); // Pass the enum value
            }
          },
          dropdownColor: dark ? BColors.darkerGrey : BColors.white,
          decoration: const InputDecoration(
            prefixIcon: Icon(Iconsax.sort),
          ),
          items: RequestFilter.values // Use the enum values
              .map(
                (RequestFilter option) => DropdownMenuItem<RequestFilter>(
              // Changed to RequestFilter
              value: option, // Value is the enum itself
              child: Text(
                  option.displayName, // Display the user-friendly name
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
