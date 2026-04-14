import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'widgets/activity_history_list.dart';
import 'widgets/activity_info_card.dart';
import 'widgets/activity_section_header.dart';
import 'widgets/activity_update_status_card.dart';
import 'widgets/receipt_photo_card.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.item});

  final CollectionItemModel item;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late String selectedDelayStatus;
  late String selectedOutcomeStatus;
  late String selectedAdministrativeStatus;
  late TextEditingController remarksController;
  late TextEditingController totalCollectedController;

  @override
  void initState() {
    super.initState();
    selectedDelayStatus = widget.item.delayStatus;
    selectedOutcomeStatus = widget.item.outcomeStatus;
    selectedAdministrativeStatus = widget.item.administrativeStatus;
    remarksController = TextEditingController(text: widget.item.remarks);
    totalCollectedController = TextEditingController(text: widget.item.totalCollected.toString());
  }

  @override
  void dispose() {
    remarksController.dispose();
    totalCollectedController.dispose();
    super.dispose();
  }

  void _saveActivity() {
    final controller = CollectionActivityController.instance;
    controller.saveActivity(
      id: widget.item.id,
      delayStatus: selectedDelayStatus,
      outcomeStatus: selectedOutcomeStatus,
      administrativeStatus: selectedAdministrativeStatus,
      remarks: remarksController.text,
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
            /// Section 1: Collection Info
            const ActivitySectionHeader(title: 'Collection Information'),
            const SizedBox(height: BSizes.spaceBtwItems),
            ActivityInfoCard(item: widget.item),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// Section 2: Photos & Documentation
            const ActivitySectionHeader(title: 'Documentation'),
            const SizedBox(height: BSizes.spaceBtwItems),
            const ReceiptPhotoCard(),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// Section 3: Update Status
            const ActivitySectionHeader(title: 'Update Status'),
            const SizedBox(height: BSizes.spaceBtwItems),
            ActivityUpdateStatusCard(
              selectedDelayStatus: selectedDelayStatus,
              selectedOutcomeStatus: selectedOutcomeStatus,
              selectedAdministrativeStatus: selectedAdministrativeStatus,
              remarksController: remarksController,
              totalCollectedController: totalCollectedController,
              onDelayChanged: (val) => setState(() => selectedDelayStatus = val!),
              onOutcomeChanged: (val) => setState(() => selectedOutcomeStatus = val!),
              onAdministrativeChanged: (val) => setState(() => selectedAdministrativeStatus = val!),
            ),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveActivity,
                child: const Text('Save & Move to Bucket'),
              ),
            ),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// Section 3: Account History
            const ActivitySectionHeader(title: 'Account History'),
            const SizedBox(height: BSizes.spaceBtwItems),
            ActivityHistoryList(history: widget.item.history),
          ],
        ),
      ),
    );
  }
}
