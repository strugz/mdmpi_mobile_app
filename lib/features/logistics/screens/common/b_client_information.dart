import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

import '../../../../../base/utils/constants/colors.dart';
import '../../../../../base/utils/constants/sizes.dart';
import '../../../../../base/utils/popups/full_screen_loader.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../../data/controllers/client_controller.dart';

class BClientInformation extends StatelessWidget {
  const BClientInformation({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<StandardDeliveryController>();
    final dark = BHelperFunctions.isDarkMode(context);
    final selectedColor = dark ? BColors.light : BColors.darkerGrey;

    void openClientSearch() => BFullScreenLoader.showSearchSheet(
        context, Get.find<ClientController>(), requestController);

    return Obx(() {
      final client = requestController.formState.clientInformation.value;
      final hasClient = client != null && !client.isEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Client name, or a placeholder prompting selection.
              /// The whole row opens the search — not just the icon.
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: openClientSearch,
                  child: hasClient
                      ? BProductTitleText(
                          title: client.name,
                          maxLines: 1,
                          fontColor: selectedColor)
                      : const BProductTitleText(
                          title: 'Select a client',
                          maxLines: 1,
                          fontColor: BColors.darkGrey),
                ),
              ),

              //  Client Search button
              BCircularIcon(
                icon: Iconsax.search_normal,
                onPressed: openClientSearch,
              ),
            ],
          ),

          /// Address and phone number — only once a client is selected.
          if (hasClient)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BProductTitleText(
                      title: client.address,
                      maxLines: 1,
                      smallSize: true,
                      fontColor: selectedColor),
                  const SizedBox(width: BSizes.spaceBtwInputFields),
                  BProductTitleText(
                      title: client.contact,
                      maxLines: 1,
                      smallSize: true,
                      fontColor: selectedColor),
                ],
              ),
            ),
        ],
      );
    });
  }
}
