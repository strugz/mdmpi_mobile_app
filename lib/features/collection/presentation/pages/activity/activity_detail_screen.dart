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

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.item});

  final CollectionItemModel item;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late String selectedStatus;
  late TextEditingController totalCollectedController;
  late TextEditingController bankNameController;
  late TextEditingController checkNumberController;
  late TextEditingController checkDateController;
  late TextEditingController othersRemarkController;

  @override
  void initState() {
    super.initState();
    // Default to 'Collected' if current status is not a user-updatable outcome.
    if (widget.item.status.trim().isEmpty ||
        !CollectionStatusColors.updatableStatuses.contains(widget.item.status)) {
      selectedStatus = CollectionStatusColors.statusCollected;
    } else {
      selectedStatus = widget.item.status;
    }
    totalCollectedController = TextEditingController(); // Start empty

    // Pre-fill bank details from the most recent history entry that contains them
    CollectionHistoryModel? lastBankInfo;
    for (var h in widget.item.history.reversed) {
      if (h.bankName != null && h.bankName!.isNotEmpty) {
        lastBankInfo = h;
        break;
      }
    }

    bankNameController = TextEditingController(text: lastBankInfo?.bankName ?? '');
    checkNumberController = TextEditingController(text: lastBankInfo?.checkNumber ?? '');
    checkDateController = TextEditingController(text: lastBankInfo?.checkDate ?? '');

    othersRemarkController = TextEditingController();
  }

  @override
  void dispose() {
    totalCollectedController.dispose();
    bankNameController.dispose();
    checkNumberController.dispose();
    checkDateController.dispose();
    othersRemarkController.dispose();
    super.dispose();
  }

  void _saveActivity() {
    final controller = CollectionActivityController.instance;

    // If "Others" is selected, use the custom remark as both status and remark
    final String finalStatus = selectedStatus == CollectionStatusColors.statusOthers
        ? othersRemarkController.text.trim()
        : selectedStatus;

    final String finalRemarks = selectedStatus == CollectionStatusColors.statusOthers
        ? othersRemarkController.text.trim()
        : selectedStatus;

    if (selectedStatus == CollectionStatusColors.statusOthers && othersRemarkController.text.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter a remark for "Others"', backgroundColor: BColors.warning);
      return;
    }

    controller.saveActivity(
      id: widget.item.id,
      status: finalStatus.isEmpty ? 'Others' : finalStatus,
      remarks: finalRemarks.isEmpty ? 'Others' : finalRemarks,
      totalCollected: double.tryParse(totalCollectedController.text) ?? 0,
      bankName: bankNameController.text.trim().isEmpty ? null : bankNameController.text.trim(),
      checkNumber: checkNumberController.text.trim().isEmpty ? null : checkNumberController.text.trim(),
      checkDate: checkDateController.text.trim().isEmpty ? null : checkDateController.text.trim(),
      purposeOfVisit: selectedStatus == CollectionStatusColors.statusPreCollection ? 'Pre-Collection' : 'Collection',
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Engagement updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: BColors.success.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engagement Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Invoice #${widget.item.id}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  BFormatter.formatPesoCurrency(widget.item.toBeCollected),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.sm),

            Wrap(
              spacing: BSizes.sm,
              runSpacing: BSizes.sm,
              children: [
                _buildInfoTile(context, 'Due Date', widget.item.dueDate, Iconsax.timer, valueColor: BColors.error),
                _buildInfoTile(context, 'Invoice Date', widget.item.postingDate, Iconsax.calendar),
                _buildInfoTile(context, 'Account Name', widget.item.client.name, Iconsax.user, valueColor: BColors.primary),
                _buildInfoTile(context, 'Status', widget.item.status, Iconsax.activity, isBadge: true),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: BSizes.spaceBtwSections),
              child: Divider(),
            ),

            /// 1. Bank Details
            Text('Bank Details (Optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: BSizes.spaceBtwItems),
            
            TextField(
              controller: bankNameController,
              decoration: const InputDecoration(
                hintText: 'Bank Name',
                prefixIcon: Icon(Iconsax.bank),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),
            
            TextField(
              controller: checkNumberController,
              decoration: const InputDecoration(
                hintText: 'Check Number',
                prefixIcon: Icon(Iconsax.card_edit),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),
            
            TextField(
              controller: checkDateController,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  checkDateController.text = BFormatter.formatDate(date);
                }
              },
              decoration: const InputDecoration(
                hintText: 'Check Date',
                prefixIcon: Icon(Iconsax.calendar_1),
              ),
            ),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// 3. Paid to invoice
            Text('Paid to invoice', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            TextField(
              controller: totalCollectedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Enter amount collected...',
                prefixText: '₱ ',
              ),
            ),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// 4. Update Status / Remarks
            Text('Update Status / Outcome', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                hintText: 'Select status...',
                prefixIcon: Icon(Iconsax.status),
              ),
              items: CollectionStatusColors.updatableStatuses.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedStatus = newValue!;
                });
              },
            ),

            if (selectedStatus == CollectionStatusColors.statusOthers) ...[
              const SizedBox(height: BSizes.spaceBtwInputFields),
              TextField(
                controller: othersRemarkController,
                decoration: const InputDecoration(
                  hintText: 'Enter custom remarks...',
                  prefixIcon: Icon(Iconsax.edit),
                ),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: BSizes.spaceBtwSections * 1.5),

            /// 5. Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveActivity,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    {bool isBadge = false, Color? valueColor}
  ) {
    final width = (MediaQuery.of(context).size.width - (BSizes.defaultSpace * 2) - BSizes.sm) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(BSizes.sm),
      decoration: BoxDecoration(
        color: BColors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
        border: Border.all(color: BColors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BColors.primary),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                if (isBadge)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _buildStatusBadge(context, value),
                  )
                else
                  Text(
                    value, 
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final (bg, fg) = CollectionStatusColors.colorsForAuto(context, status);
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BSizes.sm,
        vertical: BSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg == BColors.white ? bg : fg,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
