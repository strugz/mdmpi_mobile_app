import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';

class MonthlySummaryScreen extends StatelessWidget {
  const MonthlySummaryScreen({
    super.key,
    required this.type,
  });

  /// 'Collection' or 'Deposit'
  final String type;

  List<DateTime> _lastNMonths(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) {
      final month = DateTime(now.year, now.month - i, 1);
      return month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TotalCollectedController>();
    final months = _lastNMonths(12);
    final isDeposit = type == 'Deposit';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDeposit ? 'Actual Collection' : 'Total Collected this Month'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          children: [
            // Month selector + total display
            Obx(() {
              final selected = controller.selectedMonth.value;
              final total = isDeposit ? controller.actualCollectionTotal : controller.monthlyTotal;
              
              return Row(
                children: [
                  Expanded(
                    child: DropdownButton<DateTime>(
                      isExpanded: true,
                      value: selected,
                      items: months.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(DateFormat('MMM yyyy').format(m)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) controller.setSelectedMonth(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Total display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total'),
                      const SizedBox(height: 6),
                      Text(
                        BFormatter.formatPesoCurrency(total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: BSizes.spaceBtwItems),

            // Search bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search), 
                hintText: isDeposit ? 'Search deposits' : 'Search collections'
              ),
              onChanged: (v) => controller.searchQuery.value = v,
            ),

            const SizedBox(height: BSizes.spaceBtwItems),

            // List header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(isDeposit ? 'Deposits' : 'Collections', style: Theme.of(context).textTheme.bodyLarge),
            ),

            const SizedBox(height: BSizes.spaceBtwItems),

            // Entries list
            Expanded(
              child: Obx(() {
                final entries = isDeposit ? controller.actualEntries : controller.monthlyEntries;
                if (entries.isEmpty) {
                  return Center(child: Text(isDeposit ? 'No deposits for this month' : 'No collections for this month'));
                }

                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return ListTile(
                      title: Text(BFormatter.formatPesoCurrency(e.amount)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account: ${e.accountName}'),
                          if (!isDeposit) Text('Invoice: ${e.invoiceNumber}'),
                          Text('${isDeposit ? 'Collector' : 'Collector'}: ${e.collectorName}'),
                        ],
                      ),
                      trailing: Text(DateFormat('MMM d, yyyy').format(e.date)),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: isDeposit ? Obx(() {
        final hasTarget = controller.targetAmount.value > 0;
        return FloatingActionButton(
          onPressed: () => _showSetTargetDialog(context, controller),
          child: Icon(hasTarget ? Icons.edit : Icons.add),
        );
      }) : null,
    );
  }

  void _showSetTargetDialog(BuildContext context, TotalCollectedController controller) {
    final TextEditingController tc = TextEditingController(
      text: controller.targetAmount.value > 0 ? controller.targetAmount.value.toStringAsFixed(2) : '',
    );

    Get.dialog(AlertDialog(
      title: const Text('Set Target Collection'),
      content: TextField(
        controller: tc,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(prefixText: '₱ '),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final v = double.tryParse(tc.text.replaceAll(',', '')) ?? 0.0;
            controller.setTargetAmount(v);
            Get.back();
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }
}
