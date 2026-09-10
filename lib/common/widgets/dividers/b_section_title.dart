import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// Left-aligned, small-caps section title with a hairline underneath.
///
/// Used instead of the centered text divider on detail screens: a centered
/// label pulls the eye to the middle of the page on every section, whereas a
/// left-aligned title sits on the same reading axis as the content below it.
/// Spacing is fixed (24 px above, 8 px below) so every section starts the
/// same way; pass [topSpacing] = 0 for the first section under a header.
class BSectionTitle extends StatelessWidget {
  const BSectionTitle(
    this.text, {
    super.key,
    this.topSpacing = BSizes.lg,
    this.bottomSpacing = BSizes.sm,
    this.trailing,
  });

  final String text;
  final double topSpacing;
  final double bottomSpacing;

  /// Optional small action on the right of the title (e.g. "Copy all").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final color = dark ? BColors.light : BColors.black;

    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.6),
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: BSizes.xs),
          Divider(height: 1, thickness: 1, color: color.withValues(alpha: 0.08)),
        ],
      ),
    );
  }
}
