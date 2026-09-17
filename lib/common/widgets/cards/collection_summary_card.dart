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
        padding: const EdgeInsets.all(BSizes.spaceBtwItemsLight),
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
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: BSizes.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: BCollectionColors.inkSecondary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
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
