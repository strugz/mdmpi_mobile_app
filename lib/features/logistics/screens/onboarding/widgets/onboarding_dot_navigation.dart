import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/authentication/controllers/onboarding/onboarding_controller.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/devices/device_utility.dart';
import '../../../../../base/utils/helpers/helper_functions.dart';


class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnBoardingController>();
    final dark = BHelperFunctions.isDarkMode(context);

    return Positioned(
      bottom: BDevicesUtils.getBottomNavigationBarHeight() + 25,
      left: BSizes.defaultSpace,
      child: SmoothPageIndicator(
        controller: controller.pageController,
        onDotClicked: controller.dotNavigationClick,
        count: 3,
        effect: ExpandingDotsEffect(
            activeDotColor: dark ? BColors.light : BColors.dark, dotHeight: 6),
      ),
    );
  }
}
