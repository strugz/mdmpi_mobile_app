import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';

/// One account's visit on a day, told once.
///
/// A collector who settles three invoices at one counter used to get three
/// near-identical cards: same account, same time, same collector, only the
/// invoice number and amount changing. The day read as longer than it was and
/// the reader had to add the amounts up themselves. This card is the visit:
/// the account, how many invoices, what they came to, and when. Tapping it
/// opens the invoices, one slim row each; tapping a row opens the same detail
/// sheet the standalone card does.
///
/// A visit of one invoice is not a group, and the calendar renders the
/// standalone [ActivityHistoryCard] for it instead of this.
class CalendarVisitCard extends StatefulWidget {
  const CalendarVisitCard({
    super.key,
    required this.accountName,
    required this.entries,
    this.initiallyExpanded = false,
  });

  /// The headline. Never empty: the calendar groups on it.
  final String accountName;

  /// The day's entries for this account, newest first, in the map shape
  /// [CollectionActivityController.activitiesByDate] builds: 'history',
  /// 'invoiceId', 'item', 'reconciledOn', 'invoiceCount'.
  final List<Map<String, dynamic>> entries;

  final bool initiallyExpanded;

  /// The same curve the rest of the collection UI opens with: fast out of the
  /// gate, so the tap feels answered, then settling.
  static const Curve curve = Cubic(0.23, 1, 0.32, 1);
  static const Duration duration = Duration(milliseconds: 220);

  @override
  State<CalendarVisitCard> createState() => _CalendarVisitCardState();
}

class _CalendarVisitCardState extends State<CalendarVisitCard> {
  late bool _expanded = widget.initiallyExpanded;

  CollectionHistoryModel _history(Map<String, dynamic> e) =>
      e['history'] as CollectionHistoryModel;

  double get _total =>
      widget.entries.fold(0.0, (sum, e) => sum + _history(e).totalCollected);

  /// "05:51 AM" when every entry shares a minute, else "05:51 – 06:21 AM".
  String get _when {
    final times = widget.entries.map((e) => _history(e).date).toList();
    if (times.isEmpty) return '';
    final latest = BFormatter.formatTimeAmPm(times.first);
    final earliest = BFormatter.formatTimeAmPm(times.last);
    if (latest == earliest) return latest;
    return '${_stripMeridiem(earliest, latest)} – $latest';
  }

  /// "05:51 AM" and "06:21 AM" read better as "05:51 – 06:21 AM"; the first
  /// keeps its suffix only when the two differ.
  String _stripMeridiem(String earlier, String later) {
    final e = earlier.split(' ');
    final l = later.split(' ');
    if (e.length == 2 && l.length == 2 && e[1] == l[1]) return e[0];
    return earlier;
  }

  /// The badge text per entry, exactly as its own card would print it.
  String _label(Map<String, dynamic> e) {
    final status = _history(e).status;
    final rec = e['reconciledOn'] as String?;
    return rec == null || rec.isEmpty
        ? status
        : '${CollectionStatusColors.statusReconciliation} $status';
  }

  /// Distinct outcomes with counts, most common first. One outcome shows
  /// without a count: "Collected", not "Collected · 3", since the invoice
  /// count is already on the line below.
  List<(String status, String label)> get _outcomes {
    final counts = <String, int>{};
    final statusFor = <String, String>{};
    for (final e in widget.entries) {
      final label = _label(e);
      counts[label] = (counts[label] ?? 0) + 1;
      statusFor[label] = _history(e).status;
    }
    final labels = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    if (labels.length == 1) return [(statusFor[labels.single]!, labels.single)];
    return [
      for (final l in labels) (statusFor[l]!, '$l · ${counts[l]}'),
    ];
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = widget.entries.length;
    final total = _total;

    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(BSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The name owns its line. Sharing it with the badges left
                  // "Al…" for an account with two outcomes, and a headline
                  // the reader cannot read is not a headline. Two lines are
                  // allowed before it truncates; the badges follow beneath.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.accountName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: BSizes.sm),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: CalendarVisitCard.duration,
                        curve: CalendarVisitCard.curve,
                        child: const Icon(Iconsax.arrow_down_1,
                            size: 18, color: BCollectionColors.inkMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: BSizes.xs + BSizes.xxs),
                  Wrap(
                    spacing: BSizes.xs,
                    runSpacing: BSizes.xs,
                    children: [
                      for (final (status, label) in _outcomes)
                        ActivityStatusBadge(status: status, label: label),
                    ],
                  ),
                  const SizedBox(height: BSizes.sm),
                  // Wrap: at a large font the day's total moves under the
                  // count instead of pushing past the card's edge.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: BSizes.sm,
                    runSpacing: BSizes.xxs,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.receipt_item,
                              size: 14, color: BCollectionColors.inkMuted),
                          const SizedBox(width: BSizes.xs),
                          Flexible(
                            child: Text(
                              '$n invoice${n == 1 ? '' : 's'} · $_when',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: BCollectionColors.inkMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (total > 0)
                        Text(
                          BFormatter.formatPesoCurrency(total),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: BCollectionColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // The rows are not dropped in, they open: the card grows to fit
          // them and the arrow turns over the same 220ms. A tap mid-motion
          // reverses from where it is; a keyframe would restart from zero.
          AnimatedSize(
            duration: CalendarVisitCard.duration,
            curve: CalendarVisitCard.curve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      const Divider(height: 1),
                      for (var i = 0; i < widget.entries.length; i++)
                        _InvoiceRow(
                          entry: widget.entries[i],
                          label: _label(widget.entries[i]),
                          last: i == widget.entries.length - 1,
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// One invoice of the visit. Tap for the same detail sheet a standalone card
/// opens.
class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.entry,
    required this.label,
    required this.last,
  });

  final Map<String, dynamic> entry;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = entry['history'] as CollectionHistoryModel;
    final invoiceId = entry['invoiceId'] as String?;
    final item = entry['item'] as CollectionItemModel?;
    final count = entry['invoiceCount'] as int?;
    final isOverdue = item?.isOverdue ?? false;

    final card = ActivityHistoryCard(
      history: history,
      invoiceId: invoiceId,
      item: item,
      reconciledOn: entry['reconciledOn'] as String?,
      invoiceCount: count,
    );

    final title = invoiceId != null && invoiceId.isNotEmpty
        ? 'Invoice #$invoiceId'
        : count != null
            ? '$count invoice${count == 1 ? '' : 's'}'
            : 'Whole account';

    final due = item?.dueDate;

    return InkWell(
      onTap: () => card.showDetail(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: BSizes.md, vertical: BSizes.sm + BSizes.xxs),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: BCollectionColors.outline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: BCollectionColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: BSizes.xs),
                  // Badge, time, due date and overdue chip wrap rather than
                  // squeeze: "Reconciliation Refused to Pay" beside a due
                  // date does not fit one line of a phone, and nothing here
                  // may be cut short to make it.
                  Wrap(
                    spacing: BSizes.xs,
                    runSpacing: BSizes.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ActivityStatusBadge(status: history.status, label: label),
                      Text(
                        BFormatter.formatTimeAmPm(history.date),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: BCollectionColors.inkMuted),
                      ),
                      if (due != null && due.isNotEmpty) ...[
                        Text(
                          '· Due $due',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isOverdue
                                ? BCollectionColors.danger
                                : BCollectionColors.inkMuted,
                            fontWeight: isOverdue ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: BCollectionColors.danger,
                            borderRadius:
                                BorderRadius.circular(BSizes.borderRadiusSm),
                          ),
                          child: Text(
                            BFormatter.formatDaysOverdue(
                                item?.daysPastDue ?? 0),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: BCollectionColors.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (history.totalCollected > 0)
              Text(
                BFormatter.formatPesoCurrency(history.totalCollected),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: BCollectionColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
