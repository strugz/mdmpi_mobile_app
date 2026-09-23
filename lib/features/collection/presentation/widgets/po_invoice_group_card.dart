import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_copy_icon_button.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/po_grouping.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/invoice_card.dart';

/// One customer P.O. as a collapsible row: the P.O., how many invoices it
/// covers and what they add up to, with the invoices themselves underneath
/// once opened.
///
/// A header is one line where three invoice cards were nine, so an account
/// with forty invoices under six P.O.s becomes six rows the collector can
/// scan, and the customer's clerk, who pays by P.O., is asked about the same
/// unit the screen shows. The state lives with the caller so it survives the
/// list rebuilding under a filter change.
class PoInvoiceGroupCard extends StatelessWidget {
  const PoInvoiceGroupCard({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggle,
    this.itemBuilder,
    this.selectedCount = 0,
  });

  final PoInvoiceGroup group;
  final bool expanded;
  final VoidCallback onToggle;

  /// Builds one invoice card under the header. The caller wires its own
  /// taps, selection and details sheet; pass `showPoNumber: false` because
  /// the header already names the P.O. Null renders a plain card.
  final Widget Function(CollectionItemModel item)? itemBuilder;

  /// How many of the group's invoices are ticked, shown on the header so a
  /// closed group never hides a selection.
  final int selectedCount;

  /// Open and close at the pace of a dropdown, not a page: the row is tapped
  /// many times a day and anything slower reads as lag. Ease-out so the first
  /// frame already moves.
  static const Duration _duration = Duration(milliseconds: 200);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = group.invoices.length;
    final overdue = group.overdueCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          label:
              'P.O. ${group.poNumber}, $count invoice${count == 1 ? '' : 's'}',
          child: BPressableScale(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: _duration,
              curve: _curve,
              padding: const EdgeInsets.symmetric(
                  horizontal: BSizes.spaceBtwItemsLight, vertical: BSizes.sm),
              decoration: BoxDecoration(
                color: expanded
                    ? BCollectionColors.primary.withValues(alpha: 0.05)
                    : BCollectionColors.surface,
                borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
                border: Border.all(
                  color: expanded
                      ? BCollectionColors.primary.withValues(alpha: 0.5)
                      : BCollectionColors.outline,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.receipt_item,
                      size: 18, color: BCollectionColors.primary),
                  const SizedBox(width: BSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PO ${group.poNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$count invoice${count == 1 ? '' : 's'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: BCollectionColors.inkMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (overdue > 0) ...[
                              const SizedBox(width: BSizes.sm),
                              _badge(theme, '$overdue overdue',
                                  BCollectionColors.danger),
                            ],
                            if (selectedCount > 0) ...[
                              const SizedBox(width: BSizes.sm),
                              _badge(theme, '$selectedCount selected',
                                  BCollectionColors.primary),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BSizes.sm),
                  Text(
                    BFormatter.formatPesoCurrency(group.totalDue),
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: BCollectionColors.primary,
                    ),
                  ),
                  // Its own target: copying never also opens or closes the P.O.
                  BCopyIconButton(
                    value: group.poNumber,
                    label: 'P.O.',
                    color: BCollectionColors.primary,
                  ),
                  // Rotates rather than swaps: one glyph turning is one thing
                  // changing state; two glyphs cross-fading is two things.
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: _duration,
                    curve: _curve,
                    child: const Icon(Iconsax.arrow_down_1,
                        size: 18, color: BCollectionColors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
        // AnimatedSize, not a conditional: the cards slide open from the
        // header instead of the list below jumping down by their height.
        AnimatedSize(
          duration: _duration,
          curve: _curve,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  // Indented under the header with a hairline on the left, so
                  // the invoices read as belonging to the P.O. above them and
                  // the next header reads as a sibling, not a child.
                  padding: const EdgeInsets.only(
                      top: BSizes.sm, left: BSizes.spaceBtwItemsLight),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: BCollectionColors.outline, width: 1.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: BSizes.sm),
                      child: Column(
                        children: [
                          for (var i = 0; i < group.invoices.length; i++) ...[
                            if (i > 0)
                              const SizedBox(height: BSizes.spaceBtwItems),
                            itemBuilder?.call(group.invoices[i]) ??
                                // The header already names the P.O.; repeating
                                // it on every card underneath says it N+1 times.
                                InvoiceCard(
                                    item: group.invoices[i],
                                    showPoNumber: false),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Tinted, not solid, like every other badge in these lists.
Widget _badge(ThemeData theme, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );

/// "No P.O." rule between the last group and the invoices that carry none.
class PoSectionLabel extends StatelessWidget {
  const PoSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: BCollectionColors.inkMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: BSizes.sm),
          const Expanded(
            child: Divider(
                height: 1, thickness: 1, color: BCollectionColors.outline),
          ),
        ],
      ),
    );
  }
}
