import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/common/widgets/icons/b_circular_icon.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

/// A compact widget that shows an icon beside a value text.
///
/// Reuses existing styling primitives: [BCircularIcon] for the icon container
/// and [BProductTitleText] for the value. Avoids business logic in build,
/// supports dark/light adaptive default colors.
class BIconValue extends StatelessWidget {
  const BIconValue({
    super.key,
    required this.icon,
    required this.value,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.gap = BSizes.xxs,
    this.smallText = true,
    this.maxLines = 1,
    this.bold = false,
    this.iconSize,
    this.hideIfEmpty = true,
  });

  final IconData icon;
  final String value;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double gap;
  final bool smallText;
  final int maxLines;
  final bool bold;
  final double? iconSize;
  final bool hideIfEmpty;

  bool get _isVisible => !hideIfEmpty || value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    final dark = BHelperFunctions.isDarkMode(context);
    final resolvedTextColor = textColor ?? (dark ? BColors.light : BColors.darkerGrey);
    final resolvedIconColor = iconColor ?? (dark ? BColors.white : BColors.black);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BCircularIcon(
            icon: icon,
            size: iconSize ?? BSizes.md,
            color: resolvedIconColor,
            backgroundColor: backgroundColor ?? Colors.transparent,
          ),
          SizedBox(width: gap),
          Flexible(
            child: BProductTitleText(
              title: value.trim(),
              smallSize: smallText,
              maxLines: maxLines,
              bold: bold,
              fontColor: resolvedTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

