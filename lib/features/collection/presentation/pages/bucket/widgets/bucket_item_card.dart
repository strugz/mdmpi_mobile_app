import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/common/widgets/chips/icon_label_chip.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';

/// A card representing a single collection bucket item.
///
/// Shows client details and document details only (no personnel).
/// Includes a selection indicator for multi-select.
class BucketItemCard extends StatelessWidget {
  const BucketItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CollectionItemModel item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? BCollectionColors.primary.withValues(alpha: 0.08)
              : dark
                  ? BCollectionColors.inkSecondary.withValues(alpha: 0.3)
                  : BCollectionColors.surface,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          border: Border.all(
            color: isSelected
                ? BCollectionColors.primary
                : BCollectionColors.outline,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: BCollectionColors.inkMuted.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? BCollectionColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? BCollectionColors.primary
                      : BCollectionColors.inkMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 16, color: BCollectionColors.surface)
                  : null,
            ),

            const SizedBox(width: BSizes.spaceBtwItemsLight),

            /// Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Client name
                  Text(
                    item.client.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: BSizes.xxs),

                  /// Client address
                  Row(
                    children: [
                      Icon(Iconsax.location,
                          size: BSizes.iconSm,
                          color: BCollectionColors.inkMuted),
                      const SizedBox(width: BSizes.xs),
                      Expanded(
                        child: Text(
                          item.client.address,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: BCollectionColors.inkMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: BSizes.sm),

                  /// Document details row
                  Row(
                    children: [
                      /// Document references
                      BIconLabelChip(
                        icon: Iconsax.document_text,
                        label: item.documentReferences.isNotEmpty
                            ? item.documentReferences.first
                            : '—',
                      ),
                      if (item.documentReferences.length > 1) ...[
                        const SizedBox(width: BSizes.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BSizes.xs + 2,
                            vertical: BSizes.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: BCollectionColors.primary
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(BSizes.borderRadiusSm),
                          ),
                          child: Text(
                            '+${item.documentReferences.length - 1}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: BCollectionColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],

                      /// Customer P.O. (SAP BP Ref. No.), only when present.
                      if (item.hasPoNumber) ...[
                        const SizedBox(width: BSizes.xs),
                        Flexible(
                          child: BIconLabelChip(
                            icon: Iconsax.receipt_item,
                            label: 'PO ${item.poNumber.trim()}',
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: BSizes.sm),

                  /// To be Collected + date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To be Collected',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: BCollectionColors.inkMuted,
                                ),
                          ),
                          Text(
                            BFormatter.formatPesoCurrency(item.toBeCollected),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: BCollectionColors.primary,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        item.documentDate,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: BCollectionColors.inkMuted,
                            ),
                      ),
                    ],
                  ),

                  /// Remarks
                  if (item.remarks.isNotEmpty) ...[
                    const SizedBox(height: BSizes.xs),
                    Text(
                      item.remarks,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BCollectionColors.inkMuted,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
