import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// A small KPI tile used on the collection home grid.
///
/// Colour carries the category, so the type can stay modest: a 12pt label
/// that may wrap to two lines (never truncates) and a 24pt value.
class CollectionSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  /// When true the card will expand to occupy available width. Set to false
  /// when placing cards horizontally inside a Row.
  final bool expand;
  final VoidCallback? onTap;

  const CollectionSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
    this.expand = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BPressableScale(
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        // Tight, because four of these sit two-by-two and the block competes
        // with the work below it for the fold. The figures are counts, rarely
        // more than four digits, so they do not need a card's worth of room.
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.spaceBtwItemsLight, vertical: BSizes.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(icon, color: color, size: 15),
                ),
                const SizedBox(width: BSizes.xs),
                Expanded(
                  child: Text(
                    title,
                    // Every label fits one line at half the card width; two
                    // are allowed so a large system text size wraps rather
                    // than truncating a category name.
                    maxLines: 2,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: BCollectionColors.inkSecondary,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
