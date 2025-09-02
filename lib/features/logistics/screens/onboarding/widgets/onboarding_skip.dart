import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/authentication/controllers/onboarding/onboarding_controller.dart';

import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/devices/device_utility.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnBoardingController>();
    return Positioned(
      top: BDevicesUtils.getAppBarHeight(),
      right: BSizes.defaultSpace,
      child: TextButton(
        onPressed: () => controller.skipPage(),
        child: const Text("Skip"),
      ),
    );
  }
}
