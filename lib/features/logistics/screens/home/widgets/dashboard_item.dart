import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// A reusable dashboard item widget displaying a label-value pair.
///
/// Used in the Activity Dashboard section of the Home screen to show
/// statistics like "Total Requests", "Delivered", etc.
class DashboardItem extends StatelessWidget {
  const DashboardItem({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.padding,
  });

  /// The label text (e.g., "Total Requests:")
  final String label;

  /// The value to display (e.g., "42")
  final String value;

  /// Optional custom style for the label text
  final TextStyle? labelStyle;

  /// Optional custom style for the value text
  final TextStyle? valueStyle;

  /// Optional custom padding
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: BSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: BSizes.sm),
          Text(
            value,
            style: valueStyle ?? Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
