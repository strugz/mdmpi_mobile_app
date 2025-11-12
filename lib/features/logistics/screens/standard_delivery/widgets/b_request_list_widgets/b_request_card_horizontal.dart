import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';

import '../../../../../../base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

class BRequestCardHorizontal extends StatelessWidget {
  const BRequestCardHorizontal({super.key, required this.requestModel});

  final StandardDeliveryModel requestModel;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Container(
      width: 310,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          color: requestModel.status == BTexts.statusCancelled
              ? BColors.cancelledBackground : null),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Client and Request Details
            BProductTitleText(
                title: requestModel.client.name,
                maxLines: 1,
                bold: true,
                fontColor: dark ? BColors.light : BColors.darkerGrey),
            const SizedBox(height: BSizes.xxs),
            // Requester and Target Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BProductTitleText(
                    title: 'Requested By: ${requestModel.requestBy}',
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.darkerGrey),
                const SizedBox(height: BSizes.xs),
                BProductTitleText(
                    title:
                        'Delivery Date: ${requestModel.deliveryDate.substring(0, 10)}',
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.darkerGrey),
              ],
            ),

            /// Shipping Method / Delivery Terms / Preference
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BProductTitleText(
                  title: 'Created By: ${requestModel.createdBy}',
                  maxLines: 1,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.darkerGrey,
                ),
                BCircularIcon(
                  backgroundColor: Colors.transparent,
                  icon: Iconsax.add_circle1,
                  color: dark ? BColors.white : BColors.black,
                  size: 5,
                  width: 20,
                  height: 20,
                ),
                BProductTitleText(
                  title: requestModel.deliveryTerms,
                  maxLines: 1,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.darkerGrey,
                ),
                BCircularIcon(
                  backgroundColor: Colors.transparent,
                  icon: Iconsax.add_circle1,
                  color: dark ? BColors.white : BColors.black,
                  size: 5,
                  width: 20,
                  height: 20,
                ),
                BProductTitleText(
                    title: requestModel.shippingMethod,
                    maxLines: 1,
                    smallSize: true,
                    fontColor: dark ? BColors.light : BColors.darkerGrey),
              ],
            ),
            Row(
              children: [
                BRoundedContainer(
                  radius: 100,
                  width: 90,
                  backgroundColor: requestModel.preference == "Low"
                      ? Colors.green
                      : requestModel.preference == "Medium"
                          ? Colors.orange
                          : Colors.red,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: BSizes.md, vertical: BSizes.xxs),
                      child: BProductTitleText(
                        title: requestModel.preference,
                        maxLines: 1,
                        smallSize: true,
                        fontColor: BColors.white,
                      ),
                    ),
                  ),
                ),
                BCircularIcon(
                  backgroundColor: Colors.transparent,
                  icon: Iconsax.add_circle1,
                  color: dark ? BColors.white : BColors.black,
                  size: 5,
                  width: 20,
                  height: 20,
                ),
                BProductTitleText(
                  title: requestModel.status,
                  maxLines: 1,
                  smallSize: true,
                  fontColor: dark ? BColors.light : BColors.darkerGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
