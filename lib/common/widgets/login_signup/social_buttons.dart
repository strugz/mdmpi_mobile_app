import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/login_controller.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/constants/image_strings.dart';
import '../../../base/utils/constants/sizes.dart';

class BSocialButtons extends StatelessWidget {
  const BSocialButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: BColors.grey),
              borderRadius: BorderRadius.circular(100)),
          child: IconButton(
              onPressed: () => controller.googleSignIn(),
              icon: const Image(
                width: BSizes.iconMd,
                height: BSizes.iconMd,
                image: AssetImage(BImages.google),
              )),
        ),
        const SizedBox(width: BSizes.spaceBtwItems),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: BColors.grey),
              borderRadius: BorderRadius.circular(100)),
          child: IconButton(
              onPressed: () {},
              icon: const Image(
                width: BSizes.iconMd,
                height: BSizes.iconMd,
                image: AssetImage(BImages.facebook),
              )),
        ),
      ],
    );
  }
}