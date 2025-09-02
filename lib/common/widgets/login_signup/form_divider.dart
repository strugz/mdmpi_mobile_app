import 'package:flutter/material.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/helpers/helper_functions.dart';

class FormDivider extends StatelessWidget {
  final String dividerText;
  const FormDivider({super.key, required this.dividerText});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Divider(
              color: dark ? BColors.darkGrey : BColors.grey,
              thickness: 0.5,
              indent: 60,
              endIndent: 5),
        ),
        Text(dividerText,style: Theme.of(context).textTheme.labelMedium),
        Flexible(
          child: Divider(
              color: dark ? BColors.darkGrey : BColors.grey,
              thickness: 0.5,
              indent: 5,
              endIndent: 60),
        ),
      ],
    );
  }
}
