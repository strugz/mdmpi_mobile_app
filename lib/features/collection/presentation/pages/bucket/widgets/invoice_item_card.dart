import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

class InvoiceItemCard extends StatelessWidget {
  final CollectionItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  const InvoiceItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: BColors.white,
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
          border: Border.all(
            color: isSelected ? BColors.primary : BColors.grey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: BColors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: BColors.primary,
            ),
            const SizedBox(width: BSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice #${item.id}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        currencyFormat.format(item.toBeCollected),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: BColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BSizes.xs),
                  Row(
                    children: [
                      const Icon(Iconsax.note, size: 16, color: BColors.darkGrey),
                      const SizedBox(width: BSizes.xs),
                      Expanded(
                        child: Text(
                          item.remarks.isEmpty ? 'No remarks' : item.remarks,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: BColors.darkGrey,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
