import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// Month-to-date money at a glance: Actual Collection (with its target) and
/// Total Collected, side by side in one card. Each half is its own tap
/// target and opens the matching monthly summary.
///
/// Replaces two stacked full-width hero cards; the figures are related and
/// read better as a pair, and the card is half the height.
class CollectionTotalsCard extends StatelessWidget {
  const CollectionTotalsCard({
    super.key,
    this.onActualTap,
    this.onCollectedTap,
  });

  final VoidCallback? onActualTap;
  final VoidCallback? onCollectedTap;

  static const Color _actualColor = BCollectionColors.primary;
  static const Color _collectedColor = BCollectionColors.success;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TotalCollectedController>()) {
      Get.lazyPut(() => TotalCollectedController(), fenix: true);
    }
    final controller = Get.find<TotalCollectedController>();

    return Obx(() {
      final actual = controller.actualCollectionTotal;
      final target = controller.targetAmount.value;
      final total = controller.monthlyTotal;

      return CollectionTotalsCardView(
        actual: BFormatter.formatPesoCurrency(actual),
        // Same wording as the Actual Collection page's target line.
        actualFootnote: target <= 0
            ? 'No target set'
            : actual >= target
                ? 'Target met'
                : '${(actual / target * 100).floor()}% of ${BFormatter.formatPesoCurrency(target)}',
        collected: BFormatter.formatPesoCurrency(total),
        onActualTap: onActualTap,
        onCollectedTap: onCollectedTap,
      );
    });
  }
}

/// Presentational half of [CollectionTotalsCard]: takes preformatted strings
/// so the layout can be rendered (and tested) without the controller.
class CollectionTotalsCardView extends StatelessWidget {
  const CollectionTotalsCardView({
    super.key,
    required this.actual,
    required this.actualFootnote,
    required this.collected,
    this.collectedFootnote = 'View breakdown',
    this.onActualTap,
    this.onCollectedTap,
  });

  final String actual;
  final String actualFootnote;
  final String collected;
  final String collectedFootnote;
  final VoidCallback? onActualTap;
  final VoidCallback? onCollectedTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BCollectionColors.surface,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusLg),
        border: Border.all(color: BCollectionColors.outline, width: 1),
      ),
      // IntrinsicHeight bounds the row so both halves match heights and the
      // divider spans them. Cross-axis stretch alone would be unbounded
      // inside a scroll view and fail layout.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _TotalsHalf(
                icon: Iconsax.bank,
                color: CollectionTotalsCard._actualColor,
                label: 'Actual Collection',
                value: actual,
                footnote: actualFootnote,
                onTap: onActualTap,
              ),
            ),
            const VerticalDivider(
                width: 1, thickness: 1, color: BCollectionColors.outline),
            Expanded(
              child: _TotalsHalf(
                icon: Iconsax.money,
                color: CollectionTotalsCard._collectedColor,
                label: 'Collected this Month',
                value: collected,
                footnote: collectedFootnote,
                onTap: onCollectedTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsHalf extends StatelessWidget {
  const _TotalsHalf({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.footnote,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String footnote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BPressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BSizes.spaceBtwItemsLight,
          vertical: BSizes.spaceBtwItemsLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: BSizes.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: BCollectionColors.inkSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),
            // Shrinks rather than wraps: a peso amount split across two
            // lines is unreadable.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: BSizes.xxs),
            Text(
              footnote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: BCollectionColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
