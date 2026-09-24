import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/area_selection/area_picker_sheet.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// The line between the search bar and the list: which area is in view, and
/// how much is in it.
///
/// The area filter was a full-width outlined button reading "Filter by Area",
/// which presents a state as a chore. Where a collector is working is the
/// frame for everything below it, so it reads as a chip — "Bohol" with a
/// clear mark, or "All areas" — and the count beside it says what that frame
/// contains. Together they take one 36pt row where the button took fifty.
class BucketToolbar extends StatelessWidget {
  const BucketToolbar({super.key});

  static const Duration _stateDuration = Duration(milliseconds: 160);

  /// The sheet rises from the chip that opens it, rather than pushing a
  /// screen for one choice out of nine.
  Future<void> _pickArea(BuildContext context) async {
    final controller = CollectionActivityController.instance;
    final chosen = await AreaPickerSheet.show(
      context,
      selected: controller.selectedArea.value,
      countFor: controller.accountCountForArea,
    );
    if (chosen != null) controller.selectedArea.value = chosen;
  }

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.sm),
      child: Obx(() {
        final area = controller.selectedArea.value;
        final hasArea = area.isNotEmpty;
        final summary = controller.bucketSummary;

        final summaryStyle = theme.textTheme.bodySmall?.copyWith(
          color: BCollectionColors.inkMuted,
          fontWeight: FontWeight.w600,
        );

        return Row(
          children: [
            // The chip gives way first. Its label is one the collector just
            // chose and can see selected, so losing characters there costs
            // nothing; the total has no other source on this screen.
            Flexible(
              child: _AreaChip(
                label: hasArea ? BCollectionArea.labelFor(area) : 'All areas',
                active: hasArea,
                onTap: () => _pickArea(context),
                onClear:
                    hasArea ? () => controller.selectedArea.value = '' : null,
                duration: _stateDuration,
              ),
            ),
            const SizedBox(width: BSizes.sm),
            // The count goes before the money does. It is recoverable by
            // looking at the list; the money is not.
            Flexible(
              child: Text(
                '${summary.accounts} account${summary.accounts == 1 ? '' : 's'} ·',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: summaryStyle,
              ),
            ),
            const SizedBox(width: 4),
            // Never shrinks and never ellipsizes. A cut figure is not a
            // shorter number, it is a wrong one: "₱4…" reads as four pesos
            // and could be four hundred million.
            Text(compactPeso(summary.due), maxLines: 1, style: summaryStyle),
          ],
        );
      }),
    );
  }

  /// ₱12.4M rather than ₱12,432,110.00: this is a sense of scale, not a
  /// figure anyone reconciles against, and the long form does not fit beside
  /// the chip on a phone.
  @visibleForTesting
  static String compactPeso(double amount) {
    if (amount >= 1000000) {
      return '₱${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 10000) {
      return '₱${(amount / 1000).toStringAsFixed(0)}k';
    }
    return BFormatter.formatPesoCurrency(amount);
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.onClear,
    required this.duration,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        active ? BCollectionColors.primary : BCollectionColors.inkSecondary;

    return BPressableScale(
      onTap: onTap,
      pressedScale: 0.96,
      child: Semantics(
        button: true,
        label: active ? 'Area: $label' : 'Choose an area',
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          height: 36,
          padding: EdgeInsets.only(
            left: BSizes.spaceBtwItemsLight,
            // The clear mark carries its own inner padding.
            right: onClear == null ? BSizes.spaceBtwItemsLight : BSizes.xs,
          ),
          decoration: BoxDecoration(
            color: active
                ? BCollectionColors.primary.withValues(alpha: 0.10)
                : BCollectionColors.surface,
            borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
            border: Border.all(
                color: active
                    ? BCollectionColors.primary
                    : BCollectionColors.outline,
                width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.map, size: 15, color: accent),
              const SizedBox(width: BSizes.xs),
              // Capped so a long territory never crowds the total, and
              // Flexible so it can give up more than the cap when the row is
              // tight. This is the label that ellipsizes on this line.
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (onClear != null)
                // Its own target, so clearing the area does not open the
                // picker, and 32pt so it can be hit without aiming.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.all(BSizes.xs),
                    child: Icon(Iconsax.close_circle5,
                        size: 16, color: BCollectionColors.primary),
                  ),
                )
              else ...[
                const SizedBox(width: BSizes.xs),
                Icon(Iconsax.arrow_down_1, size: 13, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
