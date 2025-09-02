import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/devices/device_utility.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

class BSearchContainer extends StatelessWidget {
  const BSearchContainer({
    super.key,
    required this.text,
    this.icon = Iconsax.search_normal,
    this.showBackground = true,
    this.showBorder = true,
    this.onTap,

  });

  final String text;
  final IconData? icon;
  final bool showBackground, showBorder;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final darkMode = BHelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace),
        child: Container(
          width: BDevicesUtils.getScreenWidth(context),
          padding: EdgeInsets.all(BSizes.md),
          decoration: BoxDecoration(
              color: showBackground
                  ? darkMode
                  ? BColors.dark
                  : BColors.light
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
              border: showBorder ? Border.all(color: BColors.grey) : null),
          child: Row(
            children: [
              Icon(icon, color: BColors.grey),
              const SizedBox(width: BSizes.spaceBtwItems),
              Text(text,
                  style: Theme.of(context).textTheme.bodySmall)
            ],
          ),
        ),
      ),
    );
  }
}
