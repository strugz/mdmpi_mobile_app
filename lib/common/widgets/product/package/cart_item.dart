import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/images/b_rounded_image.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_product_title_text_with_verified_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';

import '../../../../base/utils/constants/colors.dart';
import '../../../../base/utils/constants/image_strings.dart';
import '../../../../base/utils/constants/sizes.dart';
import '../../../../base/utils/helpers/helper_functions.dart';

class BCartItem extends StatelessWidget {
  const BCartItem({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// Image
        BRoundedImage(
          imageUrl: BImages.product1,
          width: 60,
          height: 60,
          padding: EdgeInsets.all(BSizes.sm),
          backgroundColor: BHelperFunctions.isDarkMode(context)
              ? BColors.darkerGrey
              : BColors.light,
        ),
        const SizedBox(width: BSizes.spaceBtwItems),
        /// Title, Price & Size
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BProductTitleWIthVerifiedIcon(title: 'BIO-RAD'),
              const Flexible(child: BProductTitleText(title: 'Access HCV Ab V3', maxLines: 1)),
              /// Attributes
              Text.rich(
                  TextSpan(
                      children: [
                        TextSpan(text: 'Color', style: Theme.of(context).textTheme.bodySmall),
                        TextSpan(text: 'Green', style: Theme.of(context).textTheme.bodyLarge),
                        TextSpan(text: 'Size', style: Theme.of(context).textTheme.bodySmall),
                        TextSpan(text: 'UK 08', style: Theme.of(context).textTheme.bodyLarge),
                      ]
                  )
              )
            ],
          ),
        )
      ],
    );
  }
}