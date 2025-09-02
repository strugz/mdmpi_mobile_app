import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/images/b_rounded_image.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_product_title_text_with_verified_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_price_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';

class BProductCardHorizontal extends StatelessWidget {
  const BProductCardHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Container(
      width: 310,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BSizes.productImageRadius),
          color: dark ? BColors.darkerGrey : BColors.grey),
      child: Row(
        children: [
          /// Thumbnail
          BRoundedContainer(
            height: 120,
            padding: const EdgeInsets.all(BSizes.sm),
            backgroundColor: dark ? BColors.dark : BColors.white,
            child: Stack(
              children: [
                /// --  Thumbnail Image
                SizedBox(
                    height: 120,
                    width: 120,
                    child: BRoundedImage(
                        imageUrl: BImages.product3, applyImageRadius: true)),
              ],
            ),
          ),

          /// Details
          SizedBox(
            width: 172,
            child: Padding(
              padding: const EdgeInsets.only(top: BSizes.sm, left: BSizes.sm),
              child: Column(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BProductTitleText(
                        title: 'DxH 900 Hematology Analyzer',
                        smallSize: true,
                      ),
                      SizedBox(height: BSizes.spaceBtwItems / 2),
                      BProductTitleWIthVerifiedIcon(title: 'Beckman Coulter')
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Pricing
                      Flexible(
                          child: BProductPriceText(unit: 'In-stock', qty: '')),

                      /// Add Qty
                      Container(
                        decoration: BoxDecoration(
                          color: BColors.dark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(BSizes.cardRadiusMd),
                            bottomRight:
                                Radius.circular(BSizes.productImageRadius),
                          ),
                        ),
                        child: SizedBox(
                          width: BSizes.iconLg * 1.2,
                          height: BSizes.iconLg * 1.2,
                          child: Center(
                              child: Icon(Iconsax.add, color: BColors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
