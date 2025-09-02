
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/helpers/helper_functions.dart';

class BDropDownDynamicList extends StatelessWidget {
  const BDropDownDynamicList({
    super.key,
    required this.label,
    required this.dropdownList,
    this.icon = Iconsax.airplane,
    required this.controller, // This will now store the selected ID
    required this.valueKey, // Key to use for the value (e.g., 'Initial' or 'id')
    required this.displayKey, // Key to use for display (e.g., 'FullName')
    required this.onChanged,
  });

  final String label;
  final List<Map<String, dynamic>> dropdownList;
  final IconData icon;
  final TextEditingController
      controller; // Assuming controller stores the selected ID as a String
  final String valueKey;
  final String displayKey;
  final ValueChanged<String?> onChanged; // Callback for when selection changes


  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(
        context); // Assuming BHelperFunctions is available
    return DropdownButtonFormField<String>(
      // Specify the type for DropdownButtonFormField
      menuMaxHeight: 200.0,
      value: controller.text.isEmpty ? null : controller.text,
      onChanged: (String? newValue) {
        if (newValue != null) {
          controller.text = newValue;
          onChanged(newValue); // Notify parent about the change
        }
      },
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: dark
              ? BColors.white.withOpacity(0.9)
              : BColors.black.withOpacity(0.9), // Assuming BColors is available
        ),
        labelText: label,
        labelStyle: TextStyle(color: BColors.darkGrey), // Assuming BColors is available
      ),
      items: dropdownList.map((option) {
        return DropdownMenuItem<String>(
          value: option[valueKey] as String, // Use the unique ID as the value
          child: Text(
            option[displayKey] as String, // Use the display key for the text
            style: Theme.of(context).textTheme.labelSmall,
          ),
        );
      }).toList(),
      // Ensure no duplicate values in items
      validator: (value) {
        if (value == null && dropdownList.isNotEmpty) {
          // if you want to make it required
          // return 'Please select an option';
        }
        return null;
      },
    );
  }
}
