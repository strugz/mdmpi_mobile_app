import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

class BDropdown extends StatelessWidget {
  const BDropdown(
      {super.key,
      required this.label,
      required this.dropdownList,
      this.icon = Iconsax.airplane,
      required this.controller});

  final String label;
  final List<String> dropdownList;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          DropdownButtonFormField(
              value: controller.text.isEmpty ? null : controller.text,
              onChanged: (value) {
                controller.text = value!;
              },
              decoration: InputDecoration(
                prefixIcon: Icon(icon,
                    color: dark
                        ? BColors.white.withOpacity(0.9)
                        : BColors.black.withOpacity(0.9)),
                labelText: label,
                labelStyle: TextStyle(color: BColors.darkGrey),
              ),
              items: dropdownList
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  )
                  .toList()),
        ],
      ),
    );
  }
}
