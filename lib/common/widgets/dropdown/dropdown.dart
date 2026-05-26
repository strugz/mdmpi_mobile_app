// ignore_for_file: deprecated_member_use

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
      required this.controller,
      this.validator});

  final String label;
  final List<String> dropdownList;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(dynamic)? validator;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final List<String> options = [];
    final seen = <String>{};
    for (final option in dropdownList) {
      if (!seen.contains(option)) {
        seen.add(option);
        options.add(option);
      }
    }
    if (options.isEmpty) {
      options.add('');
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          DropdownButtonFormField(
              value: (controller.text.isEmpty || !options.contains(controller.text))
                  ? null
                  : controller.text,
              onChanged: (value) {
                controller.text = value!;
              },
              validator: validator,
              decoration: InputDecoration(
                prefixIcon: Icon(icon,
                    color: dark
                        ? BColors.white.withOpacity(0.9)
                        : BColors.black.withOpacity(0.9)),
                labelText: label,
                labelStyle: TextStyle(color: BColors.darkGrey),
                // When validation fails we want a visible red outline so the user
                // immediately sees the required field. Keep default look until
                // an error occurs by only specifying the error borders.
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              items: options
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
