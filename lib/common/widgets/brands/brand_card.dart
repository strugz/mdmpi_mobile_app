import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/images/b_circular_image.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_product_title_text_with_verified_icon.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/constants/enums.dart';
import '../../../base/utils/constants/image_strings.dart';
import '../../../base/utils/constants/sizes.dart';
import '../../../base/utils/helpers/helper_functions.dart';

class BBrandCard extends StatelessWidget {
  const BBrandCard({
    super.key,
    required this.showBorder,
    this.onTap,
  });

  final bool showBorder;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BRoundedContainer(
        padding: EdgeInsets.all(BSizes.sm),
        showBorder: showBorder,
        backgroundColor: Colors.transparent,
        child: Row(
          children: [
            /// --  Icon
            Flexible(
              child: BCircularImage(
                  image: BImages.requestInstrumentIcon,
                  isNetworkImage: false,
                  backgroundColor: Colors.transparent,
                  overlayColor: BHelperFunctions.isDarkMode(context)
                      ? BColors.white
                      : BColors.black),
            ),
            const SizedBox(width: BSizes.spaceBtwItems / 2),

            /// --  Text
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BProductTitleWIthVerifiedIcon(
                      title: 'Machine', brandTextSize: TextSizes.large),
                  Text('10 Requests',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
