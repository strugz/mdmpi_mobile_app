import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({
    super.key,
    required this.history,
    this.accountNames,
    this.invoiceIds,
  });

  final List<CollectionHistoryModel> history;
  
  /// Optional: Map of history index to account name (for global lists)
  final Map<int, String>? accountNames;
  
  /// Optional: Map of history index to invoice ID (for global lists)
  final Map<int, String>? invoiceIds;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: BSizes.lg),
          child: Text('No history available.'),
        ),
      );
    }

    // The history is already sorted newest-first by the controller.
    final List<CollectionHistoryModel> displayList = history;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        return _ActivityHistoryCard(
          history: displayList[index],
          accountName: accountNames?[index],
          invoiceId: invoiceIds?[index],
        );
      },
    );
  }
}

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({
    required this.history,
    this.accountName,
    this.invoiceId,
  });

  final CollectionHistoryModel history;
  final String? accountName;
  final String? invoiceId;

  @override
  Widget build(BuildContext context) {
    String displayCollectorName = history.collectorName;
    if (displayCollectorName == 'You') {
      displayCollectorName = UserController.instance.user.value.initials;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header: Date and Collector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(history.date, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  displayCollectorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BColors.darkGrey),
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),

            /// Optional: Account & Invoice Info (for Home Screen)
            if (accountName != null || invoiceId != null) ...[
              Text(
                '${accountName ?? 'Unknown'} ${invoiceId != null ? '(#$invoiceId)' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: BSizes.xs),
            ],

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
            
            _ActivityHistoryBadge(status: history.status),
            
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
