import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

/// Full page for viewing bucket item details.
/// Replaces the previous modal bottom sheet when tapping a bucket card.
class BucketItemDetailsScreen extends StatefulWidget {
  const BucketItemDetailsScreen({super.key, required this.item});

  final CollectionItemModel item;

  @override
  State<BucketItemDetailsScreen> createState() => _BucketItemDetailsScreenState();
}

class _BucketItemDetailsScreenState extends State<BucketItemDetailsScreen> {
  String? selectedAction;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Details', style: Theme.of(context).textTheme.headlineSmall),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CollectionStatusColors.colorFor(item.status),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          CollectionStatusColors.iconFor(item.status),
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: BSizes.sm),
                    Text(
                      CollectionStatusColors.display(item.status),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: CollectionStatusColors.colorFor(item.status),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (item.assignedAt.isNotEmpty)
                  Text(
                    'Assigned: ${item.assignedAt}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: BColors.darkGrey),
                  ),
              ],
            ),
            const SizedBox(height: BSizes.spaceBtwSections),

            // Client Info Card
            _buildSectionHeader(context, 'Client Information', Iconsax.user),
            const SizedBox(height: BSizes.sm),
            Card(
              elevation: 0,
              color: BColors.lightGrey.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.borderRadiusLg)),
              child: Padding(
                padding: const EdgeInsets.all(BSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.client.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: BSizes.xs),
                    _buildInfoRow(context, Iconsax.location, item.client.address),
                    if (item.client.contact.isNotEmpty) 
                      _buildInfoRow(context, Iconsax.call, item.client.contact),
                    if (item.client.emailAddress.isNotEmpty) 
                      _buildInfoRow(context, Iconsax.direct, item.client.emailAddress),
                    if (item.client.code.isNotEmpty) 
                      _buildInfoRow(context, Iconsax.code, 'Client Code: ${item.client.code}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),

            // Collection Details Card
            _buildSectionHeader(context, 'Collection Details', Iconsax.document_text),
            const SizedBox(height: BSizes.sm),
            Card(
              elevation: 0,
              color: BColors.lightGrey.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.borderRadiusLg)),
              child: Padding(
                padding: const EdgeInsets.all(BSizes.md),
                child: Column(
                  children: [
                    _buildDataRow(context, 'Amount to Collect', BFormatter.formatPesoCurrency(item.amount), isHighlight: true),
                    const Divider(),
                    _buildDataRow(context, 'Document Date', item.documentDate),
                    const Divider(),
                    _buildDataRow(context, 'Bank Name', item.bankName.isNotEmpty ? item.bankName : 'Not Specified'),
                    if (item.documentReferences.isNotEmpty) ...[
                      const Divider(),
                      _buildDataRow(context, 'References', item.documentReferences.join(', ')),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: BSizes.spaceBtwSections),

            // Remarks Section
            if (item.remarks.isNotEmpty) ...[
              _buildSectionHeader(context, 'Remarks', Iconsax.note),
              const SizedBox(height: BSizes.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BSizes.md),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Text(
                  item.remarks,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: BSizes.spaceBtwSections),
            ],

            // Action Selection
            _buildSectionHeader(context, 'Quick Action', Iconsax.setting_4),
            const SizedBox(height: BSizes.sm),
            DropdownButtonFormField<String>(
              value: selectedAction,
              decoration: InputDecoration(
                hintText: 'Select follow-up action',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(BSizes.borderRadiusLg)),
                prefixIcon: const Icon(Iconsax.task_square),
              ),
              items: <String>['Follow up', 'Payment schedule', 'Payment']
                  .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedAction = v),
            ),

            const SizedBox(height: BSizes.spaceBtwSections * 2),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(BSizes.defaultSpace),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.back(result: selectedAction),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: BSizes.md),
              backgroundColor: BColors.primary,
            ),
            child: const Text('Update Account'),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BColors.primary),
        const SizedBox(width: BSizes.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: BSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: BColors.darkGrey),
          const SizedBox(width: BSizes.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BColors.darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BColors.darkGrey)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? BColors.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}
