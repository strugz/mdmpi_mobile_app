import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

class ReadOnlyDateFormField extends StatelessWidget {
  const ReadOnlyDateFormField({
    super.key,
    required this.controller,
    required this.label,
    this.includeTime = false,
    this.validator,
    this.icon = Iconsax.calendar,
  });

  final TextEditingController controller;
  final String label;
  final bool includeTime;
  final String? Function(String?)? validator;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final s = await BHelperFunctions.pickDateString(context, includeTime: includeTime);
        if (s != null) controller.text = s;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        labelStyle: TextStyle(color: BColors.darkGrey),
      ),
      validator: validator,
    );
  }
}

