import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';

class BProductQuantityWithAddRemove extends StatelessWidget {
  const BProductQuantityWithAddRemove({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Add Remove Buttons
        BCircularIcon(
            icon: Iconsax.minus,
            width: 32,
            height: 32,
            size: BSizes.md,
            color: BHelperFunctions.isDarkMode(context)
                ? BColors.white
                : BColors.black,
            backgroundColor: BHelperFunctions.isDarkMode(context)
                ? BColors.darkerGrey
                : BColors.light),
        const SizedBox(width: BSizes.spaceBtwItems),
        Text('2', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: BSizes.spaceBtwItems),
        BCircularIcon(
            icon: Iconsax.add,
            width: 32,
            height: 32,
            size: BSizes.md,
            color: BColors.white,
            backgroundColor: BColors.primary),
      ],
    );
  }
}