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
  late String selectedRemark;
  late TextEditingController totalCollectedController;

  @override
  void initState() {
    super.initState();
    // Use existing outcome status as the initial remark selection
    selectedRemark = widget.item.outcomeStatus;
    totalCollectedController = TextEditingController(text: widget.item.totalCollected.toString());
  }

  @override
  void dispose() {
    totalCollectedController.dispose();
    super.dispose();
  }

  void _saveActivity() {
    final controller = CollectionActivityController.instance;
    controller.saveActivity(
      id: widget.item.id,
      delayStatus: widget.item.delayStatus,
      outcomeStatus: selectedRemark, // Map dropdown to outcome status
      administrativeStatus: widget.item.administrativeStatus,
      remarks: selectedRemark, // Also use it as the text remark
      totalCollected: double.tryParse(totalCollectedController.text) ?? 0,
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Activity updated and moved back to bucket',
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
            /// 1. Invoice Header (No Section Text)
            // Invoice # and Total Amount Due
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

            // Due Date
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

            // Invoice Date and BP
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

            // Statuses
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusBadge(context, widget.item.coreStatus),
                  const SizedBox(width: BSizes.xs),
                  _buildStatusBadge(context, widget.item.delayStatus),
                  const SizedBox(width: BSizes.xs),
                  _buildStatusBadge(context, widget.item.outcomeStatus),
                  const SizedBox(width: BSizes.xs),
                  _buildStatusBadge(context, widget.item.administrativeStatus),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: BSizes.spaceBtwSections),
              child: Divider(),
            ),

            /// 2. Paid to invoice
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

            /// 3. Remarks (Dropdown)
            Text('Remarks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BSizes.spaceBtwItems),
            DropdownButtonFormField<String>(
              value: selectedRemark,
              decoration: const InputDecoration(
                hintText: 'Select remark...',
              ),
              items: [
                CollectionStatusColors.statusNone,
                ...CollectionStatusColors.subRolesFor(CollectionStatusColors.categoryOutcomes)
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedRemark = newValue!;
                });
              },
            ),

            const SizedBox(height: BSizes.spaceBtwSections * 1.5),

            /// 4. Save Button
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
    if (status == CollectionStatusColors.statusOnSchedule || status == CollectionStatusColors.statusNone) {
      return const SizedBox.shrink();
    }
    
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
