import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reports/report_month.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_reports_controller.dart';

/// "‹ September 2026 ›" over [CollectionReportsController.month]; [onChanged]
/// reloads the report.
class ReportMonthStepper extends StatelessWidget {
  const ReportMonthStepper({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = CollectionReportsController.instance;
    return Obx(() => Row(
          children: [
            IconButton(
              key: const ValueKey('report-month-back'),
              icon: const Icon(Iconsax.arrow_left_2),
              onPressed: () {
                c.stepMonth(-1);
                onChanged();
              },
            ),
            Expanded(
              child: Text(BReportMonth.label(c.month.value),
                  key: const ValueKey('report-month'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              key: const ValueKey('report-month-forward'),
              icon: const Icon(Iconsax.arrow_right_3),
              onPressed: c.canStepForward
                  ? () {
                      c.stepMonth(1);
                      onChanged();
                    }
                  : null,
            ),
          ],
        ));
  }
}

/// The report's headline figures as small labelled tiles.
class ReportSummary extends StatelessWidget {
  const ReportSummary({super.key, required this.table});

  final ReportTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: BSizes.sm,
      runSpacing: BSizes.sm,
      children: [
        for (final MapEntry(key: label, value: value) in table.summary.entries)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: BSizes.md, vertical: BSizes.sm),
            decoration: BoxDecoration(
              color: BCollectionColors.surface,
              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
              border: Border.all(color: BCollectionColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: BCollectionColors.inkMuted)),
                Text(value,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The report's rows as cards: [title], [subtitle] and [trailing] are
/// column indexes (a count in the subtitle carries its header); a tap opens
/// every column of the row.
class ReportRows extends StatelessWidget {
  const ReportRows({
    super.key,
    required this.table,
    required this.title,
    this.subtitle = const [],
    this.trailing,
    this.emptyText = 'Nothing to report.',
    this.header,
  });

  final ReportTable table;
  final int title;
  final List<int> subtitle;
  final int? trailing;
  final String emptyText;

  /// Scrolls with the rows (month stepper, summary, filters).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = table.rows;
    return ListView.builder(
      key: const ValueKey('report-rows'),
      padding: const EdgeInsets.all(BSizes.defaultSpace),
      itemCount: rows.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) return header ?? const SizedBox.shrink();
        if (i == rows.length + 1) {
          return rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: BSizes.xl),
                  child: Text(emptyText,
                      key: const ValueKey('report-empty'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: BCollectionColors.inkMuted)),
                )
              : const SizedBox(height: BSizes.spaceBtwItems);
        }
        final row = rows[i - 1];
        // A bare count means nothing on its own: "Visits 3".
        final sub = subtitle
            .map((c) => row[c].kind == ReportCellKind.integer
                ? '${table.headers[c]} ${row[c].display}'
                : row[c].display)
            .where((s) => s.trim().isNotEmpty)
            .join(' · ');
        return Card(
          margin: const EdgeInsets.only(bottom: BSizes.sm),
          child: ListTile(
            key: ValueKey('report-row-${i - 1}'),
            title: Text(row[title].display,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: sub.isEmpty
                ? null
                : Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: trailing == null
                ? null
                : Text(row[trailing!].display,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
            onTap: () => _showRow(context, row),
          ),
        );
      },
    );
  }

  void _showRow(BuildContext context, List<ReportCell> row) {
    final theme = Theme.of(context);
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          children: [
            for (var c = 0; c < table.headers.length; c++)
              if (row[c].display.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: BSizes.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(table.headers[c],
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: BCollectionColors.inkMuted)),
                      ),
                      Expanded(
                          flex: 3,
                          child: Text(row[c].display,
                              style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: BCollectionColors.surface,
    );
  }
}

/// Save and Share at the bottom, the navigation bar padded once here.
class ReportExportBar extends StatelessWidget {
  const ReportExportBar({
    super.key,
    required this.table,
    required this.fileName,
  });

  /// Null while loading or failed: both buttons are off.
  final ReportTable? Function() table;
  final String Function() fileName;

  @override
  Widget build(BuildContext context) {
    final c = CollectionReportsController.instance;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            BSizes.defaultSpace,
            BSizes.spaceBtwItemsLight,
            BSizes.defaultSpace,
            BSizes.spaceBtwItemsLight),
        decoration: const BoxDecoration(
          color: BCollectionColors.surface,
          border: Border(top: BorderSide(color: BCollectionColors.outline)),
        ),
        child: Obx(() {
          final t = table();
          final enabled = t != null && !t.isEmpty && !c.isExporting.value;
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('report-share'),
                  onPressed: enabled ? () => _share(c, t) : null,
                  icon: const Icon(Iconsax.share, size: 18),
                  label: const Text('Share CSV'),
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
              const SizedBox(width: BSizes.sm),
              Expanded(
                child: ElevatedButton.icon(
                  key: const ValueKey('report-save'),
                  onPressed: enabled ? () => _save(c, t) : null,
                  icon: const Icon(Iconsax.document_download, size: 18),
                  label: const Text('Save CSV'),
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _save(CollectionReportsController c, ReportTable t) async {
    final r = await c.save(t, fileName());
    if (r.isFailure) {
      BLoaders.errorSnackBar(title: 'Not saved', message: r.error);
    } else if (r.value != null) {
      BLoaders.successSnackBar(title: 'Report saved', message: fileName());
    }
  }

  Future<void> _share(CollectionReportsController c, ReportTable t) async {
    final r = await c.share(t, fileName());
    if (r.isFailure) {
      BLoaders.errorSnackBar(title: 'Not shared', message: r.error);
    }
  }
}

/// A loading spinner, an error, or [child].
class ReportBody extends StatelessWidget {
  const ReportBody({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.child,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(BSizes.defaultSpace),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: BSizes.sm),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        child,
        if (loading)
          const Positioned(
              top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
      ],
    );
  }
}
