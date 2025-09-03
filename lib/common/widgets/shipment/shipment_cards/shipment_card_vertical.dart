import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/styles/shadows.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';

class BShipmentCardVertical extends StatelessWidget {
  const BShipmentCardVertical({super.key, this.showAddButton = true});

  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 300,
        height: 200,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
            boxShadow: [BShadowStyle.verticalProductShadow],
            borderRadius: BorderRadius.circular(BSizes.productImageRadius),
            color: dark ? BColors.darkerGrey : BColors.light),
        child: Column(
          children: [
            /// Thumbnail,
            BRoundedContainer(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(BSizes.sm),
              backgroundColor: dark ? BColors.dark : BColors.white,
              child: Stack(
                children: [
                  /// --- Shipment Information
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          BProductTitleText(
                              textAlign: TextAlign.center,
                              title: 'Chinese General Hospital Medical Center',
                              maxLines: 2,
                              smallSize: true,
                              fontColor: dark ? BColors.light : BColors.black),
                          BCircularIcon(
                              icon: Iconsax.truck_time,
                              color: dark ? BColors.white : BColors.dark,
                              size: BSizes.md,
                              width: 30,
                              height: 30),
                          BProductTitleText(
                              textAlign: TextAlign.center,
                              title: 'ETA: 25 mins',
                              smallSize: true,
                              fontColor: dark ? BColors.light : BColors.black),
                          SizedBox(height: BSizes.xs),
                          BRoundedContainer(
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.8,
                            padding:
                                const EdgeInsets.symmetric(vertical: BSizes.xs),
                            backgroundColor:
                                dark ? BColors.darkerGrey : BColors.light,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                BCircularIcon(
                                    icon: Iconsax.user,
                                    color: dark ? BColors.white : BColors.dark,
                                    size: BSizes.md,
                                    width: 30,
                                    height: 30),
                                Expanded(
                                  child: BProductTitleText(
                                      textAlign: TextAlign.center,
                                      title: 'Dispatcher: JCA',
                                      smallSize: true,
                                      maxLines: 1,
                                      fontColor:
                                          dark ? BColors.light : BColors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// --- Shipment Date
                  Positioned(
                    child: BRoundedContainer(
                      radius: BSizes.sm,
                      // ignore: deprecated_member_use
                      backgroundColor: BColors.secondary.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: BSizes.sm, vertical: BSizes.xs),
                      child: Text('RF# 111221122',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .apply(color: BColors.black)),
                    ),
                  ),

                  /// --  Status Icon
                  Positioned(
                      bottom: 0,
                      right: 3,
                      child: BCircularIcon(
                          iconImage: AssetImage(BImages.onGoingPackage),
                          icon: Iconsax.box_time,
                          color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
