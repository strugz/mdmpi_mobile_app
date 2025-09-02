import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/enums.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/b_product_title_text.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/constants/sizes.dart';

class BProductTitleWIthVerifiedIcon extends StatelessWidget {
  const BProductTitleWIthVerifiedIcon({
    super.key,
    required this.title,
    this.maxLines = 1,
    this.textColor,
    this.iconColor = BColors.primary,
    this.textAlign = TextAlign.center,
    this.brandTextSize = TextSizes.small,
  });

  final String title;
  final int maxLines;
  final Color? textColor, iconColor;
  final TextAlign? textAlign;
  final TextSizes brandTextSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: BProductTitleText(
            title: title,
            maxLines: maxLines,
            color: textColor,
            textAlign: textAlign,
            brandTextSize: brandTextSize,
          ),
        ),
        const SizedBox(width: BSizes.xs),
        const Icon(Iconsax.verify5, color: BColors.primary, size: BSizes.iconXs)
      ],
    );
  }
}
