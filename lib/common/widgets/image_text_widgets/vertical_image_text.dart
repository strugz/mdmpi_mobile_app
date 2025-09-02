import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/images/b_circular_image.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/constants/sizes.dart';
import '../../../base/utils/helpers/helper_functions.dart';

class BVerticalImageText extends StatelessWidget {
  const BVerticalImageText({
    super.key,
    required this.image,
    required this.title,
    this.textColor = BColors.white,
    this.backgroundColor,
    this.onTap,
    this.isNetworkImage = true,
  });

  final String image, title;
  final Color textColor;
  final Color? backgroundColor;
  final bool isNetworkImage;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: BSizes.spaceBtwItems),
        child: Column(
          children: [
            Expanded(
              child: BCircularImage(
                image: image,
                fit: BoxFit.fitWidth,
                padding: BSizes.xs * 1.2,
                isNetworkImage: isNetworkImage,
                backgroundColor: backgroundColor,
                overlayColor: BHelperFunctions.isDarkMode(context)
                    ? BColors.light
                    : BColors.dark,
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwItems / 2),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .apply(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
