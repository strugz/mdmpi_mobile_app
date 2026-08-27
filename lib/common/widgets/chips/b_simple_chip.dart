import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// A small reusable tag/chip for inline metadata like batch ids.
class BSimpleChip extends StatelessWidget {
  const BSimpleChip({
    super.key,
    required this.label,
    this.prefix,
    this.padding,
    this.textStyle,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final Widget? prefix;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final bg = backgroundColor ?? (dark ? BColors.darkerGrey : BColors.light);
    final border = borderColor ?? (dark ? BColors.light : BColors.grey);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: BSizes.sm, vertical: BSizes.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: BSizes.xs)],
          // Make label flexible so the chip can shrink in tight horizontal constraints
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: BSizes.fontSizeSm),
            ),
          ),
        ],
      ),
    );
  }
}


