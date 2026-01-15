// filepath: lib/common/widgets/dividers/text_divider.dart
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// A horizontal divider with a text label centered between two lines.
///
/// Usage:
/// BTextDivider(text: 'Section');
///
/// If [text] is empty, a plain Divider is rendered.
class BTextDivider extends StatelessWidget {
  const BTextDivider({
    super.key,
    required this.text,
    this.thickness = 1.0,
    this.lineColor,
    this.textStyle,
    this.verticalPadding = BSizes.xs,
    this.gap = BSizes.xs,
  });

  final String text;
  final double thickness;
  final Color? lineColor;
  final TextStyle? textStyle;
  final double verticalPadding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Divider(thickness: thickness, color: lineColor),
      );
    }
    final dark = BHelperFunctions.isDarkMode(context);
    final color = lineColor ?? (dark ? BColors.light.withValues(alpha: 0.3) : BColors.black.withValues(alpha: 0.2));
    final style = textStyle ?? Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: dark ? BColors.light.withValues(alpha: 0.7) : BColors.black.withValues(alpha: 0.6),
        );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          Expanded(child: Divider(thickness: thickness, color: color, height: thickness)),
          SizedBox(width: gap),
          Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(width: gap),
          Expanded(child: Divider(thickness: thickness, color: color, height: thickness)),
        ],
      ),
    );
  }
}

