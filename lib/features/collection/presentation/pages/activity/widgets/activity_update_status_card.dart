import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

class ActivityUpdateStatusCard extends StatelessWidget {
  const ActivityUpdateStatusCard({
    super.key,
    required this.selectedOutcomeStatus,
    required this.remarksController,
    required this.totalCollectedController,
    required this.onOutcomeChanged,
  });

  final String selectedOutcomeStatus;
  final TextEditingController remarksController;
  final TextEditingController totalCollectedController;
  final ValueChanged<String?> onOutcomeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.cardRadiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          children: [
            _ActivityStatusDropdown(
              label: 'Type of Payment',
              value: selectedOutcomeStatus,
              items: [
                CollectionStatusColors.statusNone,
                ...CollectionStatusColors.subRolesFor(CollectionStatusColors.categoryOutcomes)
              ],
              onChanged: onOutcomeChanged,
            ),
            const SizedBox(height: BSizes.spaceBtwInputFields),
            TextField(
              controller: totalCollectedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total Collected',
                hintText: 'Enter amount collected...',
                prefixText: '₱ ',
              ),
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
}

class _ActivityStatusDropdown extends StatelessWidget {
  const _ActivityStatusDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
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
}
