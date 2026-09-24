import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/common/widgets/buttons/b_copy_icon_button.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/po_grouping.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/invoice_details_modal.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// An account's P.O.s and the invoices under each, on a page of its own.
///
/// This used to open inside the account's card on the list, and on an account
/// with five P.O.s the card grew to fill the screen and pushed every other
/// account out of view — on a screen whose job is picking between accounts.
/// Here the breakdown has the room it needs, and the list stays a list.
///
/// Read-only by design. Recording, claiming and selecting stay where they
/// already are; this page answers "what is this account made of", and the
/// customer's clerk asks that question by P.O.
class AccountPoInvoicesScreen extends StatefulWidget {
  const AccountPoInvoicesScreen({
    super.key,
    required this.client,
    required this.invoices,
  });

  final ClientModel client;

  /// Read inside an [Obx], so the page follows the list it was opened from
  /// (an upload or a download while it is open updates it in place).
  final List<CollectionItemModel> Function() invoices;

  @override
  State<AccountPoInvoicesScreen> createState() =>
      _AccountPoInvoicesScreenState();
}

class _AccountPoInvoicesScreenState extends State<AccountPoInvoicesScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// Groups the collector has closed. Everything starts open: seeing the
  /// invoices under each P.O. is what this page is for.
  final Set<String> _collapsed = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// A P.O. matches as a whole (all its invoices stay); otherwise only the
  /// invoices whose number matches are kept under it.
  PoGrouping _filtered(PoGrouping all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    bool hit(CollectionItemModel i) => i.id.toLowerCase().contains(q);
    return PoGrouping(
      groups: [
        for (final g in all.groups)
          if (g.poNumber.toLowerCase().contains(q))
            g
          else if (g.invoices.any(hit))
            PoInvoiceGroup(
                poNumber: g.poNumber, invoices: g.invoices.where(hit).toList()),
      ],
      ungrouped: all.ungrouped.where(hit).toList(),
    );
  }

  void _openInvoice(CollectionItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.paddingOf(sheetContext).bottom),
        child: InvoiceDetailsModal(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final invoices = widget.invoices();
      final all = PoGrouping.of(invoices);
      final shown = _filtered(all);
      final total = invoices.fold(0.0, (s, i) => s + i.toBeCollected);
      final overdue = invoices.where((i) => i.isOverdue).length;
      final poCount = all.groups.length;
      final n = invoices.length;

      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Two lines in the bar: the name takes a title role one step
              // below the bar's own title so the pair fits the toolbar.
              Text(widget.client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: BCollectionColors.onHeader)),
              Text(
                '$poCount P.O.${poCount == 1 ? '' : 's'} · $n invoice${n == 1 ? '' : 's'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: BCollectionColors.onHeaderMuted),
              ),
            ],
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    BSizes.defaultSpace, BSizes.sm, BSizes.defaultSpace, 0),
                child: _Summary(total: total, overdue: overdue),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(BSizes.defaultSpace),
                // No fixed height: a dense field sizes to its text, so it
                // grows with the system font size instead of clipping it.
                child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      hintStyle: theme.textTheme.bodyMedium
                          ?.copyWith(color: BCollectionColors.inkMuted),
                      hintText: 'Search P.O. or invoice number',
                      prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Iconsax.close_circle5, size: 18),
                              color: BCollectionColors.inkMuted,
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(BSizes.borderRadiusMd)),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: BSizes.sm),
                    ),
                  ),
              ),
            ),
            if (shown.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _query.isEmpty
                        ? 'No open invoices.'
                        : 'No P.O. or invoice matches "$_query".',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: BCollectionColors.inkMuted),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  BSizes.defaultSpace,
                  0,
                  BSizes.defaultSpace,
                  BSizes.defaultSpace + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList.list(children: [
                  for (final g in shown.groups) ...[
                    _PoSection(
                      key: ValueKey('po-${g.key}'),
                      title: 'PO ${g.poNumber}',
                      copyValue: g.poNumber,
                      invoices: g.invoices,
                      // A search keeps every match in view.
                      open: _query.isNotEmpty || !_collapsed.contains(g.key),
                      onToggle: () => setState(() {
                        if (!_collapsed.remove(g.key)) _collapsed.add(g.key);
                      }),
                      onInvoiceTap: _openInvoice,
                    ),
                    const SizedBox(height: BSizes.spaceBtwItems),
                  ],
                  if (shown.ungrouped.isNotEmpty)
                    _PoSection(
                      key: const ValueKey('po-none'),
                      title: 'No P.O.',
                      invoices: shown.ungrouped,
                      open: _query.isNotEmpty || !_collapsed.contains('none'),
                      onToggle: () => setState(() {
                        if (!_collapsed.remove('none')) _collapsed.add('none');
                      }),
                      onInvoiceTap: _openInvoice,
                    ),
                ]),
              ),
          ],
        ),
      );
    });
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.total, required this.overdue});

  final double total;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To be collected',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: BCollectionColors.inkMuted)),
              // The one large figure on the page; everything below is
              // smaller, so this is where the eye lands first. Shrinks
              // rather than wraps when a big balance meets a narrow phone.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  BFormatter.formatPesoCurrency(total),
                  maxLines: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: BCollectionColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (overdue > 0) _Badge('$overdue overdue', BCollectionColors.danger),
      ],
    );
  }
}

/// One P.O. as a card: header with the number, a copy control, its total and
/// count; then one row per invoice. Tapping the header folds it.
class _PoSection extends StatelessWidget {
  const _PoSection({
    super.key,
    required this.title,
    required this.invoices,
    required this.open,
    required this.onToggle,
    required this.onInvoiceTap,
    this.copyValue,
  });

  final String title;
  final String? copyValue;
  final List<CollectionItemModel> invoices;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<CollectionItemModel> onInvoiceTap;

  static const Duration _duration = Duration(milliseconds: 200);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = invoices.fold(0.0, (s, i) => s + i.toBeCollected);
    final overdue = invoices.where((i) => i.isOverdue).length;
    final n = invoices.length;
    final named = copyValue != null;

    return Container(
      decoration: BoxDecoration(
        color: BCollectionColors.surface,
        borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
        border: Border.all(color: BCollectionColors.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: '$title, $n invoice${n == 1 ? '' : 's'}',
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    BSizes.spaceBtwItemsLight, BSizes.sm, BSizes.xs, BSizes.sm),
                child: Row(
                  children: [
                    Icon(named ? Iconsax.receipt_item : Iconsax.document_text,
                        size: 18,
                        color: named
                            ? BCollectionColors.primary
                            : BCollectionColors.inkMuted),
                    const SizedBox(width: BSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Two lines allowed: P.O.s run to 46 characters and
                          // this is the one place a whole one fits.
                          // The copy glyph sits against the number it copies;
                          // beside the total it read as "copy the amount".
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: named
                                          ? BCollectionColors.ink
                                          : BCollectionColors.inkSecondary,
                                    )),
                              ),
                              if (named)
                                BCopyIconButton(
                                  value: copyValue!,
                                  label: 'P.O.',
                                  size: 14,
                                  dense: true,
                                  color: BCollectionColors.inkMuted,
                                ),
                            ],
                          ),
                          const SizedBox(height: BSizes.xxs),
                          // Count, then overdue as a badge as on the account
                          // cards. A Wrap, not a Row: at a large font size the
                          // badge drops under the count instead of overflowing.
                          Wrap(
                            spacing: BSizes.xs,
                            runSpacing: BSizes.xxs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '$n invoice${n == 1 ? '' : 's'}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: BCollectionColors.inkMuted),
                              ),
                              if (overdue > 0)
                                _Badge('$overdue overdue',
                                    BCollectionColors.danger),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(BFormatter.formatPesoCurrency(total),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: BCollectionColors.primary,
                        )),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: _duration,
                      curve: _curve,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Iconsax.arrow_down_1,
                            size: 18, color: BCollectionColors.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: _duration,
            curve: _curve,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    children: [
                      for (final inv in invoices) ...[
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: BCollectionColors.outline),
                        _InvoiceRow(item: inv, onTap: () => onInvoiceTap(inv)),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// One invoice: number with its copy control, due date and how late, amount.
/// Tapping opens the invoice's details sheet.
class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.item, required this.onTap});

  final CollectionItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = item.dueDate.trim();
    final hasDue = due.isNotEmpty && due != 'N/A';

    return BPressableScale(
      onTap: onTap,
      pressedScale: 0.99,
      child: Container(
        color: BCollectionColors.surface,
        padding: const EdgeInsets.fromLTRB(
            BSizes.spaceBtwItemsLight + 26, 6, BSizes.xs, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('#${item.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      BCopyIconButton(
                        value: item.id,
                        label: 'Invoice',
                        size: 14,
                        color: BCollectionColors.inkMuted,
                      ),
                    ],
                  ),
                  Text(
                    hasDue
                        ? 'Due ${BFormatter.formatDate3(due)}'
                        : 'No due date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: BSizes.sm),
            // How late sits under the amount, not after the date: the two
            // together overran the line and wrapped every overdue row.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(BFormatter.formatPesoCurrency(item.toBeCollected),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BCollectionColors.ink,
                    )),
                if (hasDue && item.isOverdue)
                  Text(BFormatter.formatDaysOverdue(item.daysPastDue),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: BCollectionColors.danger,
                      )),
              ],
            ),
            const SizedBox(width: BSizes.xs),
            const Icon(Iconsax.arrow_right_3,
                size: 14, color: BCollectionColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Tinted status pill, the same as the badges on the account cards.
class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}
