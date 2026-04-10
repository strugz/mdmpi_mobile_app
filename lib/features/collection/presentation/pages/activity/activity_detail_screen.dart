import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

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

  @override
  void initState() {
    super.initState();
    selectedDelayStatus = widget.item.delayStatus;
    selectedOutcomeStatus = widget.item.outcomeStatus;
    selectedAdministrativeStatus = widget.item.administrativeStatus;
    remarksController = TextEditingController(text: widget.item.remarks);
  }

  @override
  void dispose() {
    remarksController.dispose();
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
    );

    Get.back();
    Get.snackbar(
      'Success',
      'Activity updated and moved back to bucket',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: BColors.success.withOpacity(0.8),
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
            _buildSectionHeader(context, 'Collection Information'),
            const SizedBox(height: BSizes.spaceBtwItems),
            _buildInfoCard(context),

            const SizedBox(height: BSizes.spaceBtwSections),

            /// Section 2: Update Status
            _buildSectionHeader(context, 'Update Status'),
            const SizedBox(height: BSizes.spaceBtwItems),
            _buildUpdateStatusCard(context),

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
            _detailRow(context, 'Core Status', widget.item.coreStatus),
            _detailRow(context, 'Date Assigned', widget.item.assignedAt),
            _detailRow(context, 'Collector', widget.item.collectorName),
            _detailRow(context, 'Account Name', widget.item.client.name),
            _detailRow(context, 'Address', widget.item.client.address),
            _detailRow(context, 'Bank', widget.item.bankName),
            _detailRow(context, 'Amount', BFormatter.formatPesoCurrency(widget.item.amount)),
            _detailRow(context, 'Documents', widget.item.documentReferences.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateStatusCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.cardRadiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          children: [
            _buildDropdown(
              label: 'Delay Status',
              value: selectedDelayStatus,
              items: [CollectionStatusColors.statusOnSchedule, ...CollectionStatusColors.subRolesFor(CollectionStatusColors.categoryDelays)],
              onChanged: (val) => setState(() => selectedDelayStatus = val!),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),
            _buildDropdown(
              label: 'Outcome Status',
              value: selectedOutcomeStatus,
              items: [CollectionStatusColors.statusNone, ...CollectionStatusColors.subRolesFor(CollectionStatusColors.categoryOutcomes)],
              onChanged: (val) => setState(() => selectedOutcomeStatus = val!),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),
            _buildDropdown(
              label: 'Administrative Status',
              value: selectedAdministrativeStatus,
              items: CollectionStatusColors.subRolesFor(CollectionStatusColors.categoryAdministrative),
              onChanged: (val) => setState(() => selectedAdministrativeStatus = val!),
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                hintText: 'Add any notes or updates here...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    if (widget.item.history.isEmpty) {
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
      itemCount: widget.item.history.length,
      itemBuilder: (context, index) {
        final history = widget.item.history[index];
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
