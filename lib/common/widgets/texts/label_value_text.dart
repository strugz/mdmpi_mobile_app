// filepath: lib/common/widgets/texts/label_value_text.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

/// A compact label-value line with optional copy action.
///
/// - Renders "Label: Value" with medium-weight label and normal-weight value.
/// - Set [showLabel] to false to render only the value without a label or colon.
/// - Truncates to a single line by default; set maxLines for multi-line values.
/// - When [copyable] is true and [value] is not empty, shows a trailing copy icon.
/// - Set [smallSize] to true to use smaller text styles.
class BLabelValueText extends StatelessWidget {
  const BLabelValueText({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.copyable = false,
    this.maxLines = 1,
    this.dense = true,
    this.textColor,
    this.textScaleFactor,
    this.showLabel = true,
    this.padding,
    this.mainAlignment = MainAxisAlignment.start,
    this.smallSize = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool copyable;
  final int maxLines;
  final bool dense;
  final Color? textColor;
  final double? textScaleFactor;
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final MainAxisAlignment mainAlignment;
  final bool smallSize;

  @override
  Widget build(BuildContext context) {
    final color = textColor ??
        (BHelperFunctions.isDarkMode(context) ? BColors.light : BColors.black);
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = (smallSize ? textTheme.labelLarge : textTheme.bodyMedium)?.copyWith(
          color: color,
          height: dense ? 1.1 : null,
        );
    final labelStyle = baseStyle?.copyWith(fontWeight: FontWeight.w600);
    final valueStyle = baseStyle;

    final content = Flexible(
      fit: FlexFit.loose,
      child: RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textScaler: textScaleFactor != null
            ? TextScaler.linear(textScaleFactor!)
            : MediaQuery.textScalerOf(context),
        text: TextSpan(
          children: [
            if (showLabel && label.isNotEmpty)
              TextSpan(text: '$label: ', style: labelStyle),
            TextSpan(text: value, style: valueStyle),
          ],
        ),
      ),
    );

    final children = <Widget>[
      if (icon != null) ...[
        Icon(icon, size: 16, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: BSizes.xs),
      ],
      content,
      if (copyable && value.isNotEmpty)
        IconButton(
          tooltip: showLabel && label.isNotEmpty ? 'Copy $label' : 'Copy',
          icon: const Icon(Icons.copy, size: 16),
          color: color.withValues(alpha: 0.9),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            logDebug('Copied ${showLabel ? label : 'value'}: $value');
          },
        ),
    ];

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: BSizes.xxs),
      child: Row(
          mainAxisAlignment: mainAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children),
    );
  }
}
