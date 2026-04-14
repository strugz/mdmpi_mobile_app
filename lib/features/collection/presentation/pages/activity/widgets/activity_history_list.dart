import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({super.key, required this.history});

  final List<CollectionHistoryModel> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: BSizes.lg),
          child: Text('No history available for this account.'),
        ),
      );
    }

    // Sort history to show most recent first
    final sortedHistory = history.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedHistory.length,
      itemBuilder: (context, index) {
        return _ActivityHistoryCard(history: sortedHistory[index]);
      },
    );
  }
}

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({required this.history});

  final CollectionHistoryModel history;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(history.date, style: Theme.of(context).textTheme.labelLarge),
                Text(history.collectorName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BColors.darkGrey)),
              ],
            ),
            const SizedBox(height: BSizes.xs),
            if (history.totalCollected > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: BSizes.xs),
                child: Text(
                  'Collected: ${BFormatter.formatPesoCurrency(history.totalCollected)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Wrap(
              spacing: BSizes.xs,
              runSpacing: BSizes.xs,
              children: [
                _ActivityHistoryBadge(status: history.coreStatus),
                _ActivityHistoryBadge(status: history.delayStatus),
                _ActivityHistoryBadge(status: history.outcomeStatus),
                _ActivityHistoryBadge(status: history.administrativeStatus),
              ],
            ),
            if (history.remarks.isNotEmpty && history.remarks != 'No remarks') ...[
              const SizedBox(height: BSizes.xs),
              Text(
                'Remarks: ${history.remarks}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityHistoryBadge extends StatelessWidget {
  const _ActivityHistoryBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == CollectionStatusColors.statusOnSchedule || status == CollectionStatusColors.statusNone) {
      return const SizedBox.shrink();
    }
    final (bg, _) = CollectionStatusColors.colorsForAuto(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        status,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
