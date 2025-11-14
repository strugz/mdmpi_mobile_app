import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

class FilterDropdown<T> extends StatelessWidget {
  final Rx<T> selectedFilter; // Observable for the selected filter
  final List<T> filterValues; // List of all possible filter values
  final String Function(T)
      getDisplayName; // Function to get display name for each filter
  final void Function(T) onFilterChanged; // Callback for filter change
  final double height; // Customizable height
  final double radius; // Customizable border radius

  const FilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.filterValues,
    required this.getDisplayName,
    required this.onFilterChanged,
    this.height = 50.0,
    this.radius = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return BRoundedContainer(
      radius: radius,
      height: height,
      backgroundColor: dark ? BColors.darkerGrey : BColors.white,
      child: Obx(
        () => DropdownButtonFormField<T>(
          initialValue: selectedFilter.value,
          onChanged: (T? newValue) {
            if (newValue != null) {
              onFilterChanged(newValue);
            }
          },
          dropdownColor: dark ? BColors.darkerGrey : BColors.white,
          decoration: const InputDecoration(
            prefixIcon: Icon(Iconsax.sort),
          ),
          items: filterValues
              .map(
                (T option) => DropdownMenuItem<T>(
                  value: option,
                  child: Text(
                    getDisplayName(option),
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
