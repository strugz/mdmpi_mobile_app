import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/popups/full_screen_loader.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../../data/controllers/client_controller.dart';
import '../../../controllers/request_controller.dart';

class BClientInformation extends StatelessWidget {
  const BClientInformation({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();
    final dark = BHelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// Client Information
            Obx(
              () => Expanded(
                child: BProductTitleText(
                    title: requestController.formState.clientInformation.value!.name,
                    maxLines: 1,
                    fontColor: dark ? BColors.light : BColors.darkerGrey),
              ),
            ),
            //  Client Search button
            BCircularIcon(
              icon: Iconsax.search_normal,
              onPressed: () => BFullScreenLoader.showSearchSheet(
                  context, Get.find<ClientController>(), requestController),
            ),
          ],
        ),

        /// Address and phone number
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => BProductTitleText(
                    title: requestController.formState.clientInformation.value!.address,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.darkerGrey),
              ),
              const SizedBox(width: BSizes.spaceBtwInputFields),
              Obx(
                () => BProductTitleText(
                    title: requestController.formState.clientInformation.value!.contact,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.darkerGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
