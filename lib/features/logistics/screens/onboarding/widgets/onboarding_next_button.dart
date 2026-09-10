import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/logistics_onboarding_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/devices/device_utility.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = Get.find<LogisticsOnboardingController>();
    return Positioned(
        right: BSizes.defaultSpace,
        bottom: BDevicesUtils.systemBottomInset(context) + kBottomNavigationBarHeight,
        child: ElevatedButton(
          onPressed: () => controller.nextPage(),
          style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              backgroundColor: dark ? BColors.primary : Colors.black),
          child: const Icon(Iconsax.arrow_right_3),
        ));
  }
}