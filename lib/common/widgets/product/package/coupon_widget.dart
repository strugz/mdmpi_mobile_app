// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';

class BCouponCode extends StatelessWidget {
  const BCouponCode({
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return BRoundedContainer(
      showBorder: true,
      backgroundColor: dark ? BColors.dark : BColors.white,
      padding: EdgeInsets.only(
          top: BSizes.sm,
          bottom: BSizes.sm,
          right: BSizes.sm,
          left: BSizes.md),
      child: Row(
        children: [
          /// TextField
          Flexible(
            child: TextFormField(
              decoration: InputDecoration(
                  labelText: 'Have a promo code? Enter here',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none),
            ),
          ),

          /// Button
          ElevatedButton(onPressed: () {},style: ElevatedButton.styleFrom(
              foregroundColor: dark ? BColors.white.withOpacity(0.5) : BColors.dark.withOpacity(0.5),
              backgroundColor: BColors.grey.withOpacity(0.2),
              side: BorderSide(color: BColors.grey.withOpacity(0.1))
          ), child: Text('Apply'))
        ],
      ),
    );
  }
}