import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
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
  late String selectedPurpose;
  late TextEditingController totalCollectedController;
  late TextEditingController bankNameController;
  late TextEditingController checkNumberController;
  late TextEditingController checkDateController;

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
    selectedPurpose = 'Collection';
    totalCollectedController = TextEditingController(text: widget.item.totalCollected.toString());
    bankNameController = TextEditingController();
    checkNumberController = TextEditingController();
    checkDateController = TextEditingController();
  }

  @override
  void dispose() {
    totalCollectedController.dispose();
    bankNameController.dispose();
    checkNumberController.dispose();
    checkDateController.dispose();
    super.dispose();
  }

  void _saveActivity() {
    final controller = CollectionActivityController.instance;
    controller.saveActivity(
      id: widget.item.id,
      status: selectedStatus,
      remarks: selectedStatus, // Using status as the remark text for simplicity
      totalCollected: double.tryParse(totalCollectedController.text) ?? 0,
      bankName: bankNameController.text.trim().isEmpty ? null : bankNameController.text.trim(),
      checkNumber: checkNumberController.text.trim().isEmpty ? null : checkNumberController.text.trim(),
      checkDate: checkDateController.text.trim().isEmpty ? null : checkDateController.text.trim(),
      purposeOfVisit: selectedPurpose,
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Activity updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: BColors.success.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

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
            /// 1. Invoice Header
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
            const SizedBox(height: BSizes.xs),

            Row(
              children: [
                const Icon(Iconsax.timer, size: 18, color: BColors.error),
                const SizedBox(width: BSizes.xs),
                Text(
                  'Due Date: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
                ),
                Text(
                  widget.item.dueDate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),

            Row(
              children: [
                const Icon(Iconsax.calendar, size: 16, color: BColors.darkGrey),
                const SizedBox(width: BSizes.xs),
                Text(
                  'Invoice Date: ${widget.item.postingDate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BColors.darkGrey),
                ),
                const SizedBox(width: BSizes.md),
                const Icon(Iconsax.user, size: 16, color: BColors.darkGrey),
                const SizedBox(width: BSizes.xs),
                Text(
                  'BP: ${widget.item.bpCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BSizes.sm),

            _buildStatusBadge(context, widget.item.status),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: BSizes.spaceBtwSections),
              child: Divider(),
            ),

            /// 1. Purpose of Visit
            Text('Purpose of Visit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            DropdownButtonFormField<String>(
              value: selectedPurpose,
              decoration: const InputDecoration(
                hintText: 'Select purpose...',
                prefixIcon: Icon(Iconsax.info_circle),
              ),
              items: ['Pre-Collection', 'Collection'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedPurpose = newValue!;
                });
              },
            ),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// 2. Bank Details
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
            Text('Update Status / Remarks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                hintText: 'Select status...',
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
