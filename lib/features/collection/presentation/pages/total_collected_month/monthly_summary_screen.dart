import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/devices/device_utility.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// The month's ledger: what was collected, or posted as Actual Collection,
/// when, from whom.
///
/// It read like a form. A bare dropdown for the month, "Total" tucked into
/// the same row, and every entry printed as `Account: …`, `Invoice: …`,
/// `Collector: …` — labels repeated on every row, and the collector's own
/// name on every line of their own ledger.
///
/// A ledger has a frame (the month), a headline (what it came to), and a
/// list grouped by day. So: a month stepper with the total under it; a
/// progress bar against the target where there is one; entries grouped
/// under day headers with the day's subtotal, the amount right-aligned so
/// the column can be run down by eye. The collector's name appears only
/// when the month actually has more than one collector in it.
class MonthlySummaryScreen extends StatelessWidget {
  const MonthlySummaryScreen({super.key, required this.type});

  /// 'Collection' (Collected this Month) or 'Actual' (Actual Collection)
  final String type;

  bool get _isActual => type == 'Actual';

  /// Month changes are occasional and the whole block below the stepper is
  /// replaced, so a short cross-fade rather than a hard cut.
  static const Duration _swap = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TotalCollectedController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isActual ? 'Actual Collection' : 'Collected this Month'),
      ),
      body: Column(
        children: [
          _MonthHeader(
              controller: controller, isActual: _isActual, swap: _swap),
          Expanded(
            child: Obx(() {
              final all = _isActual
                  ? controller.postedEntries
                  : controller.monthEntries;
              final shown = _isActual
                  ? controller.actualEntries
                  : controller.monthlyEntries;
              final query = controller.searchQuery.value.trim();

              return AnimatedSwitcher(
                duration: _swap,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: all.isEmpty
                    ? _EmptyMonth(
                        key: const ValueKey('empty'),
                        month: controller.selectedMonth.value,
                        isActual: _isActual,
                      )
                    : Column(
                        key: const ValueKey('list'),
                        children: [
                          _SearchField(
                            controller: controller,
                            isActual: _isActual,
                          ),
                          Expanded(
                            child: shown.isEmpty
                                ? _NoMatch(query: query)
                                : _Ledger(
                                    entries: shown,
                                    all: all,
                                    query: query,
                                    isActual: _isActual,
                                    showCollector:
                                        controller.distinctCollectors(all) > 1,
                                  ),
                          ),
                        ],
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// ‹ September 2026 › over the month's total and, for Actual Collection, the
/// target.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.controller,
    required this.isActual,
    required this.swap,
  });

  final TotalCollectedController controller;
  final bool isActual;
  final Duration swap;

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: BCollectionColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
      ),
      builder: (context) => _MonthSheet(
        months: controller.selectableMonths,
        selected: controller.selectedMonth.value,
      ),
    );
    if (picked != null) controller.setSelectedMonth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          BSizes.sm, 0, BSizes.sm, BSizes.spaceBtwItems),
      decoration: const BoxDecoration(
        color: BCollectionColors.surface,
        border: Border(bottom: BorderSide(color: BCollectionColors.outline)),
      ),
      child: Obx(() {
        final month = controller.selectedMonth.value;
        final total = isActual
            ? controller.actualCollectionTotal
            : controller.monthlyTotal;
        final entries =
            isActual ? controller.postedEntries : controller.monthEntries;
        final target = controller.targetAmount.value;

        return Column(
          // Stretch, so the headline block is pinned to the left edge whatever
          // its content measures. Left to shrink-wrap, a short "5 collections"
          // line let the whole block drift toward the centre while a wide
          // progress bar held it left — two alignments for one header.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed:
                      controller.canGoBack ? controller.previousMonth : null,
                  icon: const Icon(Iconsax.arrow_left_2, size: 20),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickMonth(context),
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(month),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: BSizes.xs),
                          const Icon(Iconsax.arrow_down_1,
                              size: 14, color: BCollectionColors.inkMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  // Disabled at the current month: nothing has been collected
                  // in a month that has not happened yet.
                  onPressed:
                      controller.canGoForward ? controller.nextMonth : null,
                  icon: const Icon(Iconsax.arrow_right_3, size: 20),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
              child: AnimatedSwitcher(
                duration: swap,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, if (current != null) current],
                ),
                child: Column(
                  key: ValueKey(month),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActual ? 'Posted' : 'Collected',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: BCollectionColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        BFormatter.formatPesoCurrency(total),
                        maxLines: 1,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          // Green is for money that came in. A month with
                          // none yet is a fact, not an achievement.
                          color: total > 0
                              ? BCollectionColors.success
                              : BCollectionColors.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: BSizes.xs),
                    if (isActual)
                      _TargetLine(
                        total: total,
                        target: target,
                        onEdit: () => _editTarget(context),
                      )
                    else
                      Text(
                        _countLine(entries),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: BCollectionColors.inkMuted),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _countLine(List<MonthlyEntry> entries) {
    if (entries.isEmpty) return 'Nothing collected yet';
    final accounts =
        entries.map((e) => e.accountName.trim().toLowerCase()).toSet().length;
    return '${entries.length} collection${entries.length == 1 ? '' : 's'} · '
        '$accounts account${accounts == 1 ? '' : 's'}';
  }

  void _editTarget(BuildContext context) {
    final tc = TextEditingController(
      text: controller.targetAmount.value > 0
          ? BFormatter.formatPesoCurrency(controller.targetAmount.value,
                  includeSymbol: false)
              .trim()
          : '',
    );

    Get.dialog(AlertDialog(
      title: Text(controller.targetAmount.value > 0
          ? 'Edit target'
          : 'Set a target for ${DateFormat('MMMM').format(controller.selectedMonth.value)}'),
      content: TextField(
        controller: tc,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [ThousandsSeparatorInputFormatter()],
        decoration: const InputDecoration(prefixText: '₱ ', hintText: '0.00'),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.setTargetAmount(BFormatter.parseAmount(tc.text));
            Get.back();
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }
}

/// Actual Collection against the month's target, or the offer to set one.
///
/// This replaces a floating action button whose only content was a pencil
/// or a plus — a target belongs next to the figure it is measured against.
class _TargetLine extends StatelessWidget {
  const _TargetLine({
    required this.total,
    required this.target,
    required this.onEdit,
  });

  final double total;
  final double target;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small =
        theme.textTheme.bodySmall?.copyWith(color: BCollectionColors.inkMuted);
    final buttonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (target <= 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onEdit,
          style: buttonStyle,
          icon: const Icon(Iconsax.flag, size: 16),
          label: const Text('Set a target'),
        ),
      );
    }

    final progress = (total / target).clamp(0.0, 1.0);
    final met = total >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            // Same tempo as the dashboard's progress bars.
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: BCollectionColors.outline,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  BCollectionColors.success),
            ),
          ),
        ),
        const SizedBox(height: BSizes.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                met
                    ? 'Target of ${BFormatter.formatPesoCurrency(target)} met'
                    : '${(progress * 100).floor()}% of ${BFormatter.formatPesoCurrency(target)} target',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: small?.copyWith(
                  color: met
                      ? BCollectionColors.success
                      : BCollectionColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onEdit,
              style: buttonStyle,
              child: const Text('Edit'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.isActual});

  final TotalCollectedController controller;
  final bool isActual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(BSizes.defaultSpace,
          BSizes.spaceBtwItemsLight, BSizes.defaultSpace, 0),
      child: SizedBox(
        height: 44,
        child: TextField(
          onChanged: (v) => controller.searchQuery.value = v,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: isActual
                ? 'Search by account or collector'
                : 'Search by account, invoice or collector',
            prefixIcon: const Icon(Iconsax.search_normal, size: 18),
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entries grouped under their day, newest day first.
class _Ledger extends StatelessWidget {
  const _Ledger({
    required this.entries,
    required this.all,
    required this.query,
    required this.isActual,
    required this.showCollector,
  });

  final List<MonthlyEntry> entries;
  final List<MonthlyEntry> all;
  final String query;
  final bool isActual;
  final bool showCollector;

  /// Group by calendar day, keeping the newest-first order of [entries].
  static List<(DateTime day, List<MonthlyEntry> items)> groupByDay(
      List<MonthlyEntry> entries) {
    final groups = <DateTime, List<MonthlyEntry>>{};
    for (final e in entries) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      groups.putIfAbsent(day, () => []).add(e);
    }
    return [for (final d in groups.keys) (d, groups[d]!)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = groupByDay(entries);
    final filtered = query.isNotEmpty;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        BSizes.defaultSpace,
        BSizes.sm,
        BSizes.defaultSpace,
        BSizes.defaultSpace + BDevicesUtils.systemBottomInset(context),
      ),
      // One header + N rows per day, plus a match line when searching.
      itemCount:
          days.fold<int>(0, (n, d) => n + 1 + d.$2.length) + (filtered ? 1 : 0),
      itemBuilder: (context, index) {
        var i = index;
        if (filtered) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: BSizes.sm),
              child: Text(
                '${entries.length} of ${all.length} match "$query"',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: BCollectionColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          i -= 1;
        }
        for (final (day, items) in days) {
          if (i == 0) return _DayHeader(day: day, items: items);
          i -= 1;
          if (i < items.length) {
            return _EntryRow(
              entry: items[i],
              isActual: isActual,
              showCollector: showCollector,
              last: i == items.length - 1,
            );
          }
          i -= items.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.items});

  final DateTime day;
  final List<MonthlyEntry> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = items.fold(0.0, (p, e) => p + e.amount);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: BCollectionColors.inkMuted,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding:
          const EdgeInsets.only(top: BSizes.spaceBtwItems, bottom: BSizes.xs),
      child: Row(
        children: [
          Expanded(
              child: Text(DateFormat('EEE, MMM d').format(day), style: style)),
          // The day's subtotal, only where it adds something.
          if (items.length > 1)
            Text(BFormatter.formatPesoCurrency(subtotal), style: style),
        ],
      ),
    );
  }
}

/// One collection: account, invoice, amount. The amount sits right so the
/// column reads top to bottom like a statement.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.isActual,
    required this.showCollector,
    required this.last,
  });

  final MonthlyEntry entry;
  final bool isActual;
  final bool showCollector;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = [
      if (!isActual) '#${entry.invoiceNumber}',
      if (showCollector) entry.collectorName,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: BSizes.spaceBtwItemsLight),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom:
                    BorderSide(color: BCollectionColors.outline, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (secondary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: BCollectionColors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: BSizes.sm),
          Text(
            BFormatter.formatPesoCurrency(entry.amount),
            style: theme.textTheme.titleSmall?.copyWith(
              color: BCollectionColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth({super.key, required this.month, required this.isActual});

  final DateTime month;
  final bool isActual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = DateFormat('MMMM').format(month);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: BSizes.defaultSpace * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BCollectionColors.primary.withValues(alpha: 0.06),
              ),
              alignment: Alignment.center,
              child: Icon(Iconsax.receipt_2,
                  size: 32,
                  color: BCollectionColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: BSizes.spaceBtwItems),
            Text(
              isActual
                  ? 'No Actual Collection posted for $name'
                  : 'Nothing collected in $name',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: BCollectionColors.inkSecondary,
              ),
            ),
            const SizedBox(height: BSizes.xs),
            Text(
              // Deposits used to fill this page. Say where they went, so a
              // collector who just logged one does not think it was lost.
              isActual
                  ? 'The office posts Actual Collection. Deposits you record '
                      'stay in your engagement history.'
                  : 'Use the arrows above to look at another month.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: BCollectionColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Text(
            'No entries match "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: BCollectionColors.inkMuted),
          ),
        ),
      );
}

/// The last twelve months, current one marked.
class _MonthSheet extends StatelessWidget {
  const _MonthSheet({required this.months, required this.selected});

  final List<DateTime> months;
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
        children: [
          for (final m in months)
            ListTile(
              dense: true,
              title: Text(
                DateFormat('MMMM yyyy').format(m),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: m == selected ? FontWeight.w700 : FontWeight.w500,
                  color: m == selected ? BCollectionColors.primary : null,
                ),
              ),
              trailing: m == selected
                  ? const Icon(Iconsax.tick_circle5,
                      color: BCollectionColors.primary, size: 20)
                  : null,
              onTap: () => Navigator.pop(context, m),
            ),
        ],
      ),
    );
  }
}
