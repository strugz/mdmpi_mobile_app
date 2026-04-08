import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.item});

  final CollectionItemModel item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Section 1: Collection Info
            _buildSectionHeader(context, 'Collection Information'),
            const SizedBox(height: BSizes.spaceBtwItems),
            _buildInfoCard(context),
            
            const SizedBox(height: BSizes.spaceBtwSections),

            /// Section 2: Account History
            _buildSectionHeader(context, 'Account History'),
            const SizedBox(height: BSizes.spaceBtwItems),
            _buildHistoryList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.cardRadiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          children: [
            _detailRow(context, 'Date Assigned', item.assignedAt),
            _detailRow(context, 'Collector', item.collectorName),
            _detailRow(context, 'Account Name', item.client.name),
            _detailRow(context, 'Address', item.client.address),
            _detailRow(context, 'Bank', item.bankName),
            _detailRow(context, 'Amount', BFormatter.formatPesoCurrency(item.amount)),
            _detailRow(context, 'Documents', item.documentReferences.join(', ')),
            _detailRow(context, 'Remarks', item.remarks.isEmpty ? 'No remarks' : item.remarks),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    if (item.history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: BSizes.lg),
          child: Text('No history available for this account.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: item.history.length,
      itemBuilder: (context, index) {
        final history = item.history[index];
        return _buildHistoryCard(context, history);
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, CollectionHistoryModel history) {
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
            const SizedBox(height: BSizes.sm),
            Wrap(
              spacing: BSizes.xs,
              runSpacing: BSizes.xs,
              children: [
                _historyBadge(context, history.coreStatus),
                _historyBadge(context, history.delayStatus),
                _historyBadge(context, history.outcomeStatus),
                _historyBadge(context, history.administrativeStatus),
              ],
            ),
            if (history.remarks.isNotEmpty) ...[
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

  Widget _historyBadge(BuildContext context, String status) {
    if (status == CollectionStatusColors.statusOnSchedule || status == CollectionStatusColors.statusNone) {
      return const SizedBox.shrink();
    }
    final (bg, fg) = CollectionStatusColors.colorsForAuto(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        status,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BColors.darkGrey)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
