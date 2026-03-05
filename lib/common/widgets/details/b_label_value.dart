import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Reusable label-value widget used across request modals for small
/// read-only fields. Optionally shows a signature widget below the value.
class BLabelValue extends StatelessWidget {
  const BLabelValue({
    Key? key,
    required this.label,
    required this.value,
    this.signature,
    this.signatureWidth = 100,
    this.signatureHeight = 50,
    this.valueTextStyle,
  }) : super(key: key);

  final String label;
  final String value;
  final Widget? signature;
  final double signatureWidth;
  final double signatureHeight;
  // Optional override for the value TextStyle. If null, falls back to theme.bodyMedium
  final TextStyle? valueTextStyle;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final textColor = dark ? BColors.light : BColors.black;

    if (value.isEmpty && signature == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: BSizes.xs),
        Text(
          value,
          // Use caller-provided style when present, otherwise use default bodyMedium
          style: (valueTextStyle != null)
              ? valueTextStyle!.copyWith(color: valueTextStyle!.color ?? textColor)
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
        ),
        if (signature != null) ...[
          const SizedBox(height: BSizes.sm),
          Container(
            padding: const EdgeInsets.all(BSizes.xs),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(BSizes.sm),
            ),
            child: SizedBox(
              width: signatureWidth,
              height: signatureHeight,
              child: signature,
            ),
          ),
        ],
      ],
    );
  }
}
