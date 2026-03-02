import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

import '../../../../../../../base/utils/constants/colors.dart';
import '../../../../../../../base/utils/constants/sizes.dart';
import '../../../../../../../base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/authentication/presentation/controllers/signup_controller.dart';

class AgreeToPolicy extends StatelessWidget {
  const AgreeToPolicy({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final controller = SignupController.instance;
    return Row(
      children: [
        SizedBox(
            width: 24,
            height: 24,
            child: Obx(() => Checkbox(value: controller.privacyPolicy.value, onChanged: (value) => controller.privacyPolicy.value = !controller.privacyPolicy.value))),
        const SizedBox(width: BSizes.spaceBtwItems),
        Text.rich(TextSpan(
          children: [
            TextSpan(
                text: '${BTexts.iAgreeTo} ',
                style: Theme.of(context).textTheme.bodySmall),
            TextSpan(
              text: '${BTexts.privacyPolicy} ',
              style: Theme.of(context).textTheme.bodyMedium!.apply(
                  color: dark ? BColors.white : BColors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: dark ? BColors.white : BColors.primary),
            ),
          ],
        ))
      ],
    );
  }
}
