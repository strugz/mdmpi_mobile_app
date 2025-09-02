import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/brands/brand_card.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/constants/sizes.dart';
import '../../../base/utils/helpers/helper_functions.dart';

class BBrandShowcase extends StatelessWidget {
  const BBrandShowcase({
    super.key,
    required this.images,
  });

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return BRoundedContainer(
      showBorder: true,
      borderColor: BColors.darkGrey,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.all(BSizes.md),
      margin: EdgeInsets.only(bottom: BSizes.spaceBtwItems),
      child: Column(
        children: [
          const BBrandCard(showBorder: false),
          SizedBox(height: BSizes.spaceBtwItems),
          Row(
              children: images
                  .map((image) => brandTopProductImageWidget(image, context))
                  .toList())
        ],
      ),
    );
  }

  Widget brandTopProductImageWidget(String image, context) {
    return Expanded(
      child: BRoundedContainer(
        height: 100,
        padding: EdgeInsets.all(BSizes.md),
        margin: EdgeInsets.only(right: BSizes.sm),
        backgroundColor: BHelperFunctions.isDarkMode(context)
            ? BColors.darkerGrey
            : BColors.light,
        child: Image(fit: BoxFit.contain, image: AssetImage(image)),
      ),
    );
  }
}