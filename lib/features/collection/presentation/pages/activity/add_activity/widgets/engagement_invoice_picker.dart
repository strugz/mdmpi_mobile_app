import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// The invoice checklist under the account on the Deposit and Reconciliation
/// forms.
///
/// One widget because the two forms had drifted: one formatted the amount as
/// pesos and the other printed the raw double, and both drew the box with a
/// hard-coded grey instead of the module's hairline. An account with no open
/// invoices used to render as an empty bordered box with no height, which
/// looked like a layout bug; it now says so.
class EngagementInvoicePicker extends StatelessWidget {
  const EngagementInvoicePicker({
    super.key,
    required this.invoices,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<CollectionItemModel> invoices;
  final List<String> selectedIds;
  final void Function(String id, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = selectedIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Invoices', style: theme.textTheme.titleSmall),
            ),
            // The count is the only feedback the form gives before Save, so
            // it sits beside the heading rather than under a snackbar later.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                count == 0
                    ? 'Pick at least one'
                    : '$count selected',
                key: ValueKey(count == 0),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: count == 0
                      ? BCollectionColors.inkMuted
                      : BCollectionColors.primary,
                  fontWeight: count == 0 ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BSizes.sm),
        Container(
          decoration: BoxDecoration(
            color: BCollectionColors.surface,
            border: Border.all(color: BCollectionColors.outline),
            borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
          ),
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(maxHeight: 250),
          child: invoices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(BSizes.md),
                  child: Row(
                    children: [
                      const Icon(Iconsax.document,
                          size: 18, color: BCollectionColors.inkMuted),
                      const SizedBox(width: BSizes.sm),
                      Expanded(
                        child: Text(
                          'No open invoices for this account.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: BCollectionColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, indent: BSizes.md, endIndent: BSizes.md),
                  itemBuilder: (context, i) {
                    final inv = invoices[i];
                    final selected = selectedIds.contains(inv.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) => onToggle(inv.id, v == true),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: BCollectionColors.primary,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: BSizes.sm),
                      title: Text(inv.id,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        // The P.O. leads when present: a customer paying "the
                        // ADC-CHEM-001 invoices" is picking by it, not by date.
                        inv.hasPoNumber
                            ? 'PO ${inv.poNumber.trim()}  ·  Due ${inv.dueDate}'
                            : 'Posted ${inv.postingDate}  ·  Due ${inv.dueDate}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: BCollectionColors.inkMuted),
                      ),
                      secondary: Text(
                        BFormatter.formatPesoCurrency(inv.toBeCollected),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: BCollectionColors.ink,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
