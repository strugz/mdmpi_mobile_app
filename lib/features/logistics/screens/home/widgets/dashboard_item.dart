import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// A reusable dashboard item widget displaying a label-value pair.
///
/// Used in the Activity Dashboard section of the Home screen to show
/// statistics like "Total Requests", "Delivered", etc. When [icon] and
/// [accent] are provided, the row renders with a tinted icon badge and a
/// colored value pill; otherwise it falls back to a plain label-value row.
class DashboardItem extends StatelessWidget {
  const DashboardItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    this.labelStyle,
    this.valueStyle,
    this.padding,
  });

  /// The label text (e.g., "Total Requests:")
  final String label;

  /// The value to display (e.g., "42")
  final String value;

  /// Optional leading icon shown in a tinted badge
  final IconData? icon;

  /// Optional accent color for the badge and value pill
  final Color? accent;

  /// Optional custom style for the label text
  final TextStyle? labelStyle;

  /// Optional custom style for the value text
  final TextStyle? valueStyle;

  /// Optional custom padding
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final accentColor = accent ?? BColors.primary;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: BSizes.xs),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(BSizes.sm),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: dark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: BSizes.spaceBtwItems / 1.5),
          ],
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: BSizes.sm),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(
              horizontal: BSizes.sm,
              vertical: BSizes.xs,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: dark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: valueStyle ??
                  Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
