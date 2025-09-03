import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/styles/shadows.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/images/b_rounded_image.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_product_title_text_with_verified_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_price_text.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';

class BProductCardVertical extends StatelessWidget {
  const  BProductCardVertical({super.key, this.showAddButton = true});

  final bool showAddButton;


  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
            boxShadow: [BShadowStyle.verticalProductShadow],
            borderRadius: BorderRadius.circular(BSizes.productImageRadius),
            color: BHelperFunctions.isDarkMode(context)
                ? BColors.darkerGrey
                : BColors.white),
        child: Column(
          children: [
            /// Thumbnail,
            BRoundedContainer(
              height: 180,
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(BSizes.sm),
              backgroundColor: dark ? BColors.dark : BColors.light,
              child: Stack(
                children: [
                  /// -- Thumbnail Image
                  Center(
                    child: BRoundedImage(
                        imageUrl: BImages.product1, applyImageRadius: true),
                  ),

                  /// --- Shipment Date
                  Positioned(
                    top: 10,
                    left: 10,
                    child: BRoundedContainer(
                      radius: BSizes.sm,
                      // ignore: deprecated_member_use
                      backgroundColor: BColors.secondary.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: BSizes.sm, vertical: BSizes.xs),
                      child: Text('12/20/2024',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .apply(color: BColors.black)),
                    ),
                  ),

                  /// --  Status Icon
                  Positioned(
                      bottom: 3,
                      right: 3,
                      child: BCircularIcon(
                          iconImage: AssetImage(BImages.onGoingPackage),
                          icon: Iconsax.box_time,
                          color: Colors.red)),
                ],
              ),
            ),

            /// Details
            Padding(
              padding: const EdgeInsets.only(left: BSizes.sm),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BProductTitleText(
                        title: 'Wash Waste Cartridge', smallSize: true),
                    const SizedBox(height: BSizes.spaceBtwItems / 2),
                    BProductTitleWIthVerifiedIcon(
                        title: 'RAPIDPoint 500 Systems')
                  ],
                ),
              ),
            ),

            Spacer(),

            /// Qty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: BSizes.sm),
                  child: BProductPriceText(unit: 'box', qty: '2'),
                ),

                /// Add Qty
                Container(
                  decoration: BoxDecoration(
                    color: showAddButton == true
                        ? BColors.black
                        : dark
                            ? BColors.darkerGrey
                            : BColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(BSizes.cardRadiusMd),
                      bottomRight: Radius.circular(BSizes.productImageRadius),
                    ),
                  ),
                  child: SizedBox(
                      width: BSizes.iconLg * 1.2,
                      height: BSizes.iconLg * 1.2,
                      child: showAddButton == false
                          ? null
                          : Center(
                              child: Icon(Iconsax.add, color: BColors.white))),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
