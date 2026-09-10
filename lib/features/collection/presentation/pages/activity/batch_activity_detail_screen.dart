import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class BatchActivityDetailScreen extends StatefulWidget {
  const BatchActivityDetailScreen({super.key, required this.items});

  final List<CollectionItemModel> items;

  @override
  State<BatchActivityDetailScreen> createState() => _BatchActivityDetailScreenState();
}

class _BatchActivityDetailScreenState extends State<BatchActivityDetailScreen> {
  late TextEditingController totalAmountController;
  late TextEditingController bankNameController;
  late TextEditingController checkNumberController;
  late TextEditingController checkDateController;

  // Track amounts and remarks per invoice ID
  final Map<String, TextEditingController> itemAmountControllers = {};
  final Map<String, TextEditingController> itemRemarkControllers = {};
  
  // Track statuses per invoice ID
  final Map<String, String> itemStatuses = {};
  // Track custom remarks for "Others" status specifically if needed, but we now have general remarks per item
  final Map<String, String> itemOthersRemarks = {};

  @override
  void initState() {
    super.initState();
    totalAmountController = TextEditingController();
    
    // Find the most recent bank info across all selected items
    CollectionHistoryModel? latestBankInfo;
    DateTime? latestDate;

    for (var item in widget.items) {
      CollectionHistoryModel? lastInfo;
      for (var h in item.history.reversed) {
        if (h.bankName != null && h.bankName!.isNotEmpty) {
          lastInfo = h;
          break;
        }
      }
      
      if (lastInfo != null) {
        try {
          final entryDate = DateTime.parse(lastInfo.date.replaceFirst(' ', 'T'));
          if (latestDate == null || entryDate.isAfter(latestDate)) {
            latestDate = entryDate;
            latestBankInfo = lastInfo;
          }
        } catch (_) {
          // If parse fails, just take it if we don't have one yet
          latestBankInfo ??= lastInfo;
        }
      }
    }

    bankNameController = TextEditingController(text: latestBankInfo?.bankName ?? '');
    checkNumberController = TextEditingController(text: latestBankInfo?.checkNumber ?? '');
    checkDateController = TextEditingController(text: latestBankInfo?.checkDate ?? '');

    for (var item in widget.items) {
      itemAmountControllers[item.id] = TextEditingController();
      itemRemarkControllers[item.id] = TextEditingController();
      // Defaulting to Collected instead of Follow Up
      itemStatuses[item.id] = CollectionStatusColors.statusCollected;
      
      // Listen to amount changes for live validation
      itemAmountControllers[item.id]!.addListener(() {
        setState(() {});
      });
    }

    totalAmountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    totalAmountController.dispose();
    bankNameController.dispose();
    checkNumberController.dispose();
    checkDateController.dispose();
    for (var controller in itemAmountControllers.values) {
      controller.dispose();
    }
    for (var controller in itemRemarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _allocatedTotal {
    double total = 0;
    for (var controller in itemAmountControllers.values) {
      total += double.tryParse(controller.text) ?? 0;
    }
    return total;
  }

  double get _targetTotal => double.tryParse(totalAmountController.text) ?? 0;

  bool get _isBalanced {
    final target = _targetTotal;
    if (target <= 0) return false;
    // Allow for small rounding differences if necessary, but usually exact for currency
    return (_allocatedTotal - target).abs() < 0.01;
  }

  void _saveBatch() {
    if (!_isBalanced) {
      Get.snackbar(
        'Imbalance', 
        'Total allocated amount (${BFormatter.formatPesoCurrency(_allocatedTotal)}) must equal total check amount (${BFormatter.formatPesoCurrency(_targetTotal)}).',
        backgroundColor: BColors.error,
        colorText: Colors.white
      );
      return;
    }

    final controller = CollectionActivityController.instance;
    
    final Map<String, String> finalStatuses = Map.from(itemStatuses);
    final Map<String, double> finalAmounts = {};
    final Map<String, String> finalRemarks = {};

    for (var item in widget.items) {
      finalAmounts[item.id] = double.tryParse(itemAmountControllers[item.id]!.text) ?? 0;
      
      // Combine status remarks with manual remarks
      String remark = itemRemarkControllers[item.id]!.text.trim();
      if (itemStatuses[item.id] == CollectionStatusColors.statusOthers) {
        finalStatuses[item.id] = itemOthersRemarks[item.id]?.isNotEmpty == true ? itemOthersRemarks[item.id]! : 'Others';
        final String statusValue = finalStatuses[item.id]!;
        remark = remark.isEmpty ? statusValue : '$remark ($statusValue)';
      }
      finalRemarks[item.id] = remark.isEmpty ? 'Batch Recording' : remark;
    }

    controller.saveBatchActivity(
      ids: widget.items.map((e) => e.id).toList(),
      statuses: finalStatuses,
      remarks: finalRemarks,
      amounts: finalAmounts,
      totalAmountReceived: _targetTotal,
      bankName: bankNameController.text.trim().isEmpty ? null : bankNameController.text.trim(),
      checkNumber: checkNumberController.text.trim().isEmpty ? null : checkNumberController.text.trim(),
      checkDate: checkDateController.text.trim().isEmpty ? null : checkDateController.text.trim(),
      purposeOfVisit: 'Collection',
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Batch engagement recorded for ${widget.items.length} invoices.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: BColors.success,
      colorText: Colors.white,
    );
  }

  void _showStatusPicker(String itemId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: BSizes.defaultSpace,
            left: BSizes.defaultSpace,
            right: BSizes.defaultSpace,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.paddingOf(context).bottom +
                BSizes.defaultSpace,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Status for Invoice #$itemId', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: BSizes.spaceBtwItems),
              ...CollectionStatusColors.updatableStatuses.map((status) => ListTile(
                title: Text(status),
                leading: Icon(CollectionStatusColors.iconFor(status), color: CollectionStatusColors.colorFor(status)),
                trailing: itemStatuses[itemId] == status ? const Icon(Iconsax.tick_circle, color: BColors.primary) : null,
                onTap: () {
                  setModalState(() {
                    itemStatuses[itemId] = status;
                  });
                  setState(() {
                    itemStatuses[itemId] = status;
                  });
                  if (status != CollectionStatusColors.statusOthers) {
                    Navigator.pop(context);
                  }
                },
              )),
              if (itemStatuses[itemId] == CollectionStatusColors.statusOthers) ...[
                const SizedBox(height: BSizes.sm),
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter custom remark...',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                  onChanged: (val) => itemOthersRemarks[itemId] = val,
                  onSubmitted: (_) => Navigator.pop(context),
                ),
                const SizedBox(height: BSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Confirm Remark'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalSelectedDue = widget.items.fold(0, (sum, item) => sum + item.toBeCollected);
    final double remaining = _targetTotal - _allocatedTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Engagement Recording'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. Summary Card
            Container(
              padding: const EdgeInsets.all(BSizes.md),
              decoration: BoxDecoration(
                color: BColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Selected Invoices', widget.items.length.toString()),
                  const Divider(),
                  _buildSummaryRow('Total Amount Due', BFormatter.formatPesoCurrency(totalSelectedDue), isBold: true),
                ],
              ),
            ),
            
            const SizedBox(height: BSizes.spaceBtwSections),

            /// 2. Visit & Bank Details
            Text('Visit & Bank Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            
            TextField(
              controller: bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name', prefixIcon: Icon(Iconsax.bank)),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: checkNumberController,
                    decoration: const InputDecoration(labelText: 'Check #', prefixIcon: Icon(Iconsax.card_edit)),
                  ),
                ),
                const SizedBox(width: BSizes.sm),
                Expanded(
                  child: TextField(
                    controller: checkDateController,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (date != null) checkDateController.text = BFormatter.formatDate(date);
                    },
                    decoration: const InputDecoration(labelText: 'Check Date', prefixIcon: Icon(Iconsax.calendar_1)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// 3. Total Amount Received
            Text('Total Amount Received', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            TextField(
              controller: totalAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: BColors.primary, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Enter total check amount...',
                prefixText: '₱ ',
              ),
            ),

            const SizedBox(height: BSizes.spaceBtwItems),
            
            /// Validation Banner
            if (_targetTotal > 0)
              Container(
                padding: const EdgeInsets.all(BSizes.md),
                decoration: BoxDecoration(
                  color: _isBalanced ? BColors.success.withOpacity(0.1) : BColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  border: Border.all(color: _isBalanced ? BColors.success : BColors.error),
                ),
                child: Row(
                  children: [
                    Icon(_isBalanced ? Iconsax.tick_circle : Iconsax.warning_2, color: _isBalanced ? BColors.success : BColors.error),
                    const SizedBox(width: BSizes.sm),
                    Expanded(
                      child: Text(
                        _isBalanced 
                          ? 'Balanced! Ready to save.' 
                          : remaining > 0 
                            ? '${BFormatter.formatPesoCurrency(remaining)} left to distribute.'
                            : '${BFormatter.formatPesoCurrency(remaining.abs())} over distributed.',
                        style: TextStyle(
                          color: _isBalanced ? BColors.success : BColors.error,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// 4. Manual Distribution
            Text('Distribute Manually', style: Theme.of(context).textTheme.titleMedium),
            Text('Specify amount and remarks for each invoice', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: BSizes.spaceBtwItems),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: BSizes.spaceBtwItems),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final currentStatus = itemStatuses[item.id] ?? '';
                final amountAllocated = double.tryParse(itemAmountControllers[item.id]!.text) ?? 0;

                return Container(
                  padding: const EdgeInsets.all(BSizes.md),
                  decoration: BoxDecoration(
                    color: BColors.white,
                    border: Border.all(color: amountAllocated > 0 ? BColors.primary : BColors.grey),
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invoice #${item.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Total Due: ${BFormatter.formatPesoCurrency(item.toBeCollected)}', style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _showStatusPicker(item.id),
                            child: _buildStatusBadge(context, currentStatus),
                          ),
                        ],
                      ),
                      const Divider(height: BSizes.lg),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: itemAmountControllers[item.id],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixText: '₱ ',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: BSizes.sm),
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: itemRemarkControllers[item.id],
                              decoration: const InputDecoration(
                                labelText: 'Remarks',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: BSizes.spaceBtwSections * 1.5),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBalanced ? _saveBatch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBalanced ? BColors.primary : BColors.grey,
                  side: BorderSide(color: _isBalanced ? BColors.primary : BColors.grey),
                ),
                child: const Text('Save Batch Engagement'),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    if (status.isEmpty) return const SizedBox.shrink();
    final (bg, _) = CollectionStatusColors.colorsForAuto(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BSizes.sm, vertical: BSizes.xxs),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status,
            style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Icon(Iconsax.edit, size: 10, color: bg),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: BColors.darkerGrey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
