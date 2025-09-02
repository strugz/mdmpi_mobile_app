import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

import '../../../base/utils/constants/colors.dart';
import '../../../base/utils/helpers/helper_functions.dart';

class BCircularIcon extends StatelessWidget {
  const BCircularIcon({
    super.key,
    this.iconImage,
    required this.icon,
    this.width,
    this.height,
    this.size = BSizes.lg,
    this.onPressed,
    this.color,
    this.backgroundColor,
  });

  final double? width, height, size;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;
  final ImageProvider<Object>? iconImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor != null
            ? backgroundColor!
            : BHelperFunctions.isDarkMode(context)
                ? BColors.black.withOpacity(0.9)
                : BColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(100),
      ),
      child: IconButton(
          onPressed: onPressed,
          icon: iconImage == null
              ? Icon(
                  icon,
                  color: color,
                  size: size,
                )
              : ImageIcon(
                  iconImage,
                  color: color,
                  size: size,
                )),
    );
  }
}
