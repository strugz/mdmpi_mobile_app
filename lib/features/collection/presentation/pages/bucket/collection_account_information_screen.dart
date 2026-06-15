import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/activity_history_list.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class CollectionAccountInformationScreen extends StatelessWidget {
  final ClientModel client;

  const CollectionAccountInformationScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final controller = CollectionActivityController.instance;
    final stats = controller.getAccountFinancialStats(client.id);
    final totalDue = controller.getAccountTotalDue(client.id);
    final history = controller.getAccountHistory(client.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. Header Section: Account Info & Total Due
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(BSizes.defaultSpace),
              decoration: const BoxDecoration(
                color: BColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(BSizes.borderRadiusLg * 2),
                  bottomRight: Radius.circular(BSizes.borderRadiusLg * 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: BColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: BSizes.xs),
                  Row(
                    children: [
                      const Icon(Iconsax.location, size: 16, color: BColors.white),
                      const SizedBox(width: BSizes.xs),
                      Expanded(
                        child: Text(
                          client.address,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BColors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BSizes.lg),
                  Text(
                    'TOTAL AMOUNT DUE',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: BColors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.2,
                        ),
                  ),
                  Text(
                    BFormatter.formatPesoCurrency(totalDue),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: BColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(BSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 2. Past Due Section
                  _buildStatRow(
                    context,
                    label: 'Total Past Amount Due',
                    value: BFormatter.formatPesoCurrency(stats['totalPastDue']),
                    icon: Iconsax.timer,
                    iconColor: BColors.error,
                  ),
                  const SizedBox(height: BSizes.xs),
                  _buildStatRow(
                    context,
                    label: 'Total # of Past Invoices Due',
                    value: stats['pastDueCount'].toString(),
                    icon: Iconsax.document_text,
                    iconColor: BColors.error,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: BSizes.spaceBtwItems),
                    child: Divider(),
                  ),

                  /// 3. Current Due Section
                  _buildStatRow(
                    context,
                    label: 'Current Amount Due',
                    value: BFormatter.formatPesoCurrency(stats['totalCurrentDue']),
                    icon: Iconsax.calendar_tick,
                    iconColor: BColors.success,
                  ),
                  const SizedBox(height: BSizes.xs),
                  _buildStatRow(
                    context,
                    label: 'Total # of Current Invoices Due',
                    value: stats['currentDueCount'].toString(),
                    icon: Iconsax.document_text,
                    iconColor: BColors.success,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: BSizes.spaceBtwItems),
                    child: Divider(),
                  ),

                  /// 4. Account Activity History
                  Text(
                    'ACCOUNT ACTIVITY HISTORY',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BColors.darkerGrey,
                        ),
                  ),
                  const SizedBox(height: BSizes.spaceBtwItems),
                  
                  if (history.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: BSizes.lg),
                        child: Text('No history found for this account.'),
                      ),
                    )
                  else
                    ActivityHistoryList(
                      history: history.map((e) => e['history'] as CollectionHistoryModel).toList(),
                      items: { for (var i = 0; i < history.length; i++) i : history[i]['item'] as CollectionItemModel? },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: BSizes.md),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: BColors.black,
              ),
        ),
      ],
    );
  }
}
