import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

class ActivityInfoCard extends StatelessWidget {
  const ActivityInfoCard({super.key, required this.item});

  final CollectionItemModel item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BSizes.cardRadiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(BSizes.md),
        child: Column(
          children: [
            _ActivityDetailRow(label: 'Core Status', value: item.coreStatus),
            _ActivityDetailRow(label: 'Date Assigned', value: item.assignedAt),
            _ActivityDetailRow(label: 'Collector', value: item.collectorName),
            _ActivityDetailRow(label: 'Account Name', value: item.client.name),
            _ActivityDetailRow(label: 'Address', value: item.client.address),
            _ActivityDetailRow(label: 'Bank', value: item.bankName),
            _ActivityDetailRow(label: 'Amount', value: BFormatter.formatPesoCurrency(item.amount)),
            _ActivityDetailRow(label: 'Documents', value: item.documentReferences.join(', ')),
          ],
        ),
      ),
    );
  }
}

class _ActivityDetailRow extends StatelessWidget {
  const _ActivityDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
