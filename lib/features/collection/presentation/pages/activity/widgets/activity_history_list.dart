import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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

  void _showDetail(BuildContext context, String collectorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: BColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(BSizes.borderRadiusLg)),
        ),
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activity Details', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: BSizes.sm),

            if (accountName != null || invoiceId != null) ...[
              Text(
                accountName ?? 'Unknown Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: BColors.primary),
              ),
              if (invoiceId != null)
                Text('Invoice #$invoiceId', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: BSizes.md),
            ],

            if (history.purposeOfVisit != null)
              _buildDetailRow(context, 'Purpose of Visit', history.purposeOfVisit!, icon: Iconsax.info_circle),

            _buildDetailRow(context, 'Date', history.date, icon: Iconsax.calendar),
            _buildDetailRow(context, 'Collector', collectorName, icon: Iconsax.user),
            _buildDetailRow(
              context, 
              'Status', 
              history.status, 
              isBadge: true,
              icon: Iconsax.activity
            ),
            
            if (history.totalCollected > 0)
              _buildDetailRow(
                context, 
                'Amount Collected', 
                BFormatter.formatPesoCurrency(history.totalCollected),
                valueColor: BColors.success,
                icon: Iconsax.wallet_money
              ),

            if (history.bankName != null && history.bankName!.isNotEmpty)
              _buildDetailRow(context, 'Bank', history.bankName!, icon: Iconsax.bank),

            if (history.checkNumber != null && history.checkNumber!.isNotEmpty)
              _buildDetailRow(context, 'Check Number', history.checkNumber!, icon: Iconsax.card_edit),

            if (history.checkDate != null && history.checkDate!.isNotEmpty)
              _buildDetailRow(context, 'Check Date', history.checkDate!, icon: Iconsax.calendar_1),

            const SizedBox(height: BSizes.md),
            Text('Remarks', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: BSizes.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BSizes.md),
              decoration: BoxDecoration(
                color: BColors.lightGrey,
                borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
              ),
              child: Text(
                history.remarks.isEmpty || history.remarks == 'No remarks' 
                    ? 'No additional remarks provided.' 
                    : history.remarks,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, 
    {bool isBadge = false, Color? valueColor, IconData? icon}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: BColors.darkGrey),
            const SizedBox(width: BSizes.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                if (isBadge)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _ActivityHistoryBadge(status: value),
                  )
                else
                  Text(
                    value, 
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                    )
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayCollectorName = history.collectorName;
    if (displayCollectorName == 'You') {
      displayCollectorName = UserController.instance.user.value.initials;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: BSizes.sm),
      child: InkWell(
        onTap: () => _showDetail(context, displayCollectorName),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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
