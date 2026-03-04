import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// A lightweight inline chip that pairs an icon with a text label.
///
/// Use for compact metadata display (e.g. bank name, document reference,
/// category tag). For richer icon-value combos with backgrounds and tap
/// handlers, see [BIconValue] in `common/widgets/icons/icon_value.dart`.
class BIconLabelChip extends StatelessWidget {
  const BIconLabelChip({
    super.key,
    required this.icon,
    required this.label,
    this.iconSize,
    this.iconColor,
    this.labelColor,
    this.labelStyle,
    this.gap,
  });

  /// Leading icon.
  final IconData icon;

  /// Text shown next to the icon.
  final String label;

  /// Icon size override (defaults to [BSizes.iconSm]).
  final double? iconSize;

  /// Icon colour override (defaults to [BColors.darkGrey]).
  final Color? iconColor;

  /// Label colour override (defaults to [BColors.darkerGrey]).
  final Color? labelColor;

  /// Full label style override. When provided, [labelColor] is ignored.
  final TextStyle? labelStyle;

  /// Spacing between icon and label (defaults to [BSizes.xxs]).
  final double? gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize ?? BSizes.iconSm, color: iconColor ?? BColors.darkGrey),
        SizedBox(width: gap ?? BSizes.xxs),
        Text(
          label,
          style: labelStyle ??
              Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: labelColor ?? BColors.darkerGrey),
        ),
      ],
    );
  }
}

