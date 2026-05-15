import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

class BatchActivityDetailScreen extends StatefulWidget {
  const BatchActivityDetailScreen({super.key, required this.items});

  final List<CollectionItemModel> items;

  @override
  State<BatchActivityDetailScreen> createState() => _BatchActivityDetailScreenState();
}

class _BatchActivityDetailScreenState extends State<BatchActivityDetailScreen> {
  late String selectedPurpose;
  late TextEditingController totalAmountController;
  late TextEditingController bankNameController;
  late TextEditingController checkNumberController;
  late TextEditingController checkDateController;

  // Track statuses per invoice ID
  final Map<String, String> itemStatuses = {};
  // Track manually overridden statuses to prevent waterfall from overwriting them
  final Set<String> manualStatusOverrides = {};

  @override
  void initState() {
    super.initState();
    selectedPurpose = 'Collection';
    totalAmountController = TextEditingController();
    bankNameController = TextEditingController();
    checkNumberController = TextEditingController();
    checkDateController = TextEditingController();

    // Initialize statuses to a default
    for (var item in widget.items) {
      itemStatuses[item.id] = CollectionStatusColors.statusFollowUp;
    }

    // Listener for waterfall logic visualization and smart defaults
    totalAmountController.addListener(() {
      _updateSmartDefaults();
      setState(() {});
    });
  }

  void _updateSmartDefaults() {
    final double inputAmount = double.tryParse(totalAmountController.text) ?? 0;
    
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      
      // Don't auto-update if the user manually picked a status for this item
      if (manualStatusOverrides.contains(item.id)) continue;

      double amountBeforeThis = 0;
      for (int j = 0; j < i; j++) {
        amountBeforeThis += widget.items[j].toBeCollected;
      }
      
      double remainingForThis = (inputAmount - amountBeforeThis).clamp(0.0, item.toBeCollected);
      
      if (remainingForThis >= item.toBeCollected && item.toBeCollected > 0) {
        itemStatuses[item.id] = CollectionStatusColors.statusCollected;
      } else if (remainingForThis > 0) {
        itemStatuses[item.id] = CollectionStatusColors.statusPartial;
      } else {
        itemStatuses[item.id] = CollectionStatusColors.statusFollowUp;
      }
    }
  }

  @override
  void dispose() {
    totalAmountController.dispose();
    bankNameController.dispose();
    checkNumberController.dispose();
    checkDateController.dispose();
    super.dispose();
  }

  void _saveBatch() {
    final controller = CollectionActivityController.instance;
    final total = double.tryParse(totalAmountController.text) ?? 0;
    
    if (total < 0) {
      Get.snackbar('Error', 'Please enter a valid amount collected.', backgroundColor: BColors.error, colorText: Colors.white);
      return;
    }

    controller.saveBatchActivity(
      ids: widget.items.map((e) => e.id).toList(),
      statuses: itemStatuses,
      remarks: 'Batch Recording',
      totalAmountReceived: total,
      bankName: bankNameController.text.trim().isEmpty ? null : bankNameController.text.trim(),
      checkNumber: checkNumberController.text.trim().isEmpty ? null : checkNumberController.text.trim(),
      checkDate: checkDateController.text.trim().isEmpty ? null : checkDateController.text.trim(),
      purposeOfVisit: selectedPurpose,
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Batch activity recorded for ${widget.items.length} invoices.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: BColors.success,
      colorText: Colors.white,
    );
  }

  void _showStatusPicker(String itemId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
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
                setState(() {
                  itemStatuses[itemId] = status;
                  manualStatusOverrides.add(itemId);
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalSelectedDue = widget.items.fold(0, (sum, item) => sum + item.toBeCollected);
    final double inputAmount = double.tryParse(totalAmountController.text) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Activity Recording'),
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

            /// 2. Purpose & Bank Details (Shared)
            Text('Visit & Bank Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            
            DropdownButtonFormField<String>(
              value: selectedPurpose,
              decoration: const InputDecoration(labelText: 'Purpose of Visit', prefixIcon: Icon(Iconsax.info_circle)),
              items: ['Pre-Collection', 'Collection'].map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (newValue) => setState(() => selectedPurpose = newValue!),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),

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

            /// 3. Total Amount Received (The Waterfall Input)
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

            const SizedBox(height: BSizes.spaceBtwSections),

            /// 4. Preview of Distribution (Waterfall)
            Text('Distribution Preview (Oldest First)', style: Theme.of(context).textTheme.titleMedium),
            Text('Tap a card to override its status', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: BSizes.spaceBtwItems),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: BSizes.sm),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final currentStatus = itemStatuses[item.id] ?? '';
                
                // Calculate how much applies to this item based on previous items
                double amountBeforeThis = 0;
                for (int i = 0; i < index; i++) {
                  amountBeforeThis += widget.items[i].toBeCollected;
                }
                
                double remainingForThis = (inputAmount - amountBeforeThis).clamp(0.0, item.toBeCollected);
                bool isFull = remainingForThis >= item.toBeCollected && item.toBeCollected > 0;

                return InkWell(
                  onTap: () => _showStatusPicker(item.id),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(BSizes.md),
                    decoration: BoxDecoration(
                      color: BColors.white,
                      border: Border.all(color: remainingForThis > 0 ? BColors.primary : BColors.grey),
                      borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Invoice #${item.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Due: ${item.dueDate}', style: Theme.of(context).textTheme.labelSmall),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  BFormatter.formatPesoCurrency(remainingForThis),
                                  style: TextStyle(
                                    color: remainingForThis > 0 ? BColors.success : BColors.darkGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isFull ? 'FULLY PAID' : (remainingForThis > 0 ? 'PARTIAL' : 'UNPAID'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: remainingForThis > 0 ? BColors.success : BColors.darkGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: BSizes.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Result Status:', style: Theme.of(context).textTheme.labelMedium),
                            _buildStatusBadge(context, currentStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: BSizes.spaceBtwSections * 1.5),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBatch,
                child: const Text('Save Batch Activity'),
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
      child: Text(
        status,
        style: TextStyle(color: bg, fontSize: 10, fontWeight: FontWeight.bold),
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
