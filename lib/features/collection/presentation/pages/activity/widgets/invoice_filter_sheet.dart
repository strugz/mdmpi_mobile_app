import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/activity_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/models/invoice_filter.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';

/// Filter and sort one account's invoices.
///
/// The sibling of the engagement sheet, and the same shape — groups of chips,
/// a quiet Reset, and an apply button carrying a live count — but every
/// question is about an invoice rather than an account. The count says
/// "Show 12 invoices", because that is what this screen shows.
///
/// The sheet edits a draft and hands it back on apply; the caller owns the
/// controller. [count] is asked for the draft on every change.
class InvoiceFilterSheet extends StatefulWidget {
  const InvoiceFilterSheet({
    super.key,
    required this.initial,
    required this.count,
  });

  final InvoiceFilter initial;

  /// How many invoices a candidate filter would leave on the list.
  final int Function(InvoiceFilter) count;

  /// Opens the sheet and resolves to the chosen filter, or null if dismissed.
  static Future<InvoiceFilter?> show(
    BuildContext context, {
    required InvoiceFilter initial,
    required int Function(InvoiceFilter) count,
  }) =>
      showModalBottomSheet<InvoiceFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BCollectionColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        builder: (_) => InvoiceFilterSheet(initial: initial, count: count),
      );

  @override
  State<InvoiceFilterSheet> createState() => _InvoiceFilterSheetState();
}

class _InvoiceFilterSheetState extends State<InvoiceFilterSheet> {
  late InvoiceFilter _draft = widget.initial;

  void _set(InvoiceFilter next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.count(_draft);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.md,
        BSizes.defaultSpace,
        BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Filter invoices',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (_draft.isActive || _draft.sort != InvoiceSort.mostOverdue)
                TextButton(
                  onPressed: () => _set(InvoiceFilter.none),
                  child: const Text('Reset'),
                ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.close_circle,
                    color: BCollectionColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: BSizes.md),
          _Group(
            title: 'Due',
            child: _chips<DueBand>(
              options: DueBand.values,
              label: (b) => b.label,
              selected: (b) => _draft.due == b,
              onTap: (b) => _set(_draft.copyWith(due: b)),
              color: (b) => b == DueBand.any
                  ? BCollectionColors.primary
                  : BCollectionColors.danger,
            ),
          ),
          _Group(
            title: 'Amount due',
            child: _chips<AmountBand>(
              options: AmountBand.values,
              label: (b) => b.label,
              selected: (b) => _draft.amount == b,
              onTap: (b) => _set(_draft.copyWith(amount: b)),
            ),
          ),
          _Group(
            title: 'Recorded',
            child: _chips<InvoiceProgress>(
              options: InvoiceProgress.values,
              label: (p) => p.label,
              selected: (p) => _draft.progress == p,
              onTap: (p) => _set(_draft.copyWith(progress: p)),
            ),
          ),
          _Group(
            title: 'Sort by',
            child: _chips<InvoiceSort>(
              options: InvoiceSort.values,
              label: (s) => s.label,
              selected: (s) => _draft.sort == s,
              onTap: (s) => _set(_draft.copyWith(sort: s)),
            ),
          ),
          const SizedBox(height: BSizes.sm),
          ElevatedButton(
            onPressed: count == 0 ? null : () => Navigator.pop(context, _draft),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              elevation: 0,
              backgroundColor: BCollectionColors.primary,
              foregroundColor: BCollectionColors.onPrimary,
              disabledBackgroundColor:
                  BCollectionColors.primary.withValues(alpha: 0.35),
              disabledForegroundColor: BCollectionColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
              ),
            ),
            child: Text(_applyLabel(count)),
          ),
        ],
      ),
    );
  }

  static String _applyLabel(int count) => switch (count) {
        0 => 'No invoices match',
        1 => 'Show 1 invoice',
        _ => 'Show $count invoices',
      };

  Widget _chips<T>({
    required List<T> options,
    required String Function(T) label,
    required bool Function(T) selected,
    required void Function(T) onTap,
    Color Function(T)? color,
  }) {
    return Wrap(
      spacing: BSizes.sm,
      runSpacing: BSizes.sm,
      children: [
        for (final o in options)
          BQuickFillChip(
            label: label(o),
            selected: selected(o),
            onTap: () => onTap(o),
            color: color?.call(o),
          ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: BCollectionColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: BSizes.sm),
          child,
        ],
      ),
    );
  }
}

/// The invoice filters in force, shown under the search bar as removable
/// chips, so a shorter list is never the only sign a filter is on.
class ActiveInvoiceFilterChips extends StatelessWidget {
  const ActiveInvoiceFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final InvoiceFilter filter;
  final ValueChanged<InvoiceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (filter.due != DueBand.any)
        _chip(filter.due.label, BCollectionColors.danger,
            () => onChanged(filter.copyWith(due: DueBand.any))),
      if (filter.amount != AmountBand.any)
        _chip(filter.amount.label, BCollectionColors.primary,
            () => onChanged(filter.copyWith(amount: AmountBand.any))),
      if (filter.progress != InvoiceProgress.any)
        _chip(filter.progress.label, BCollectionColors.primary,
            () => onChanged(filter.copyWith(progress: InvoiceProgress.any))),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BSizes.defaultSpace, 0, BSizes.defaultSpace, BSizes.sm),
      child: Wrap(spacing: BSizes.xs, runSpacing: BSizes.xs, children: chips),
    );
  }

  Widget _chip(String label, Color color, VoidCallback onRemove) {
    return InputChip(
      label: Text(label),
      labelStyle:
          TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide.none,
      deleteIcon: Icon(Iconsax.close_circle, size: 16, color: color),
      deleteButtonTooltipMessage: 'Remove $label',
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg)),
    );
  }
}
