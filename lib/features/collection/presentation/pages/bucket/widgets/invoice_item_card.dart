import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
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
    final daysPast = item.daysPastDue;
    final isOverdue = item.isOverdue;

    return GestureDetector(
      onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: isOverdue ? BColors.error.withOpacity(0.06) : BColors.white,
          borderRadius: BorderRadius.circular(BSizes.borderRadiusLg),
          border: Border.all(
            color: isSelected ? BColors.primary : BColors.grey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: BColors.black.withValues(alpha: 0.05),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice #${item.id}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'BP: ${item.bpCode}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: BColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(context, item.status),
                          if (item.lastOutcome != null) ...[
                            const SizedBox(width: BSizes.xs),
                            _buildStatusBadge(context, item.lastOutcome!),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: BSizes.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Iconsax.calendar, size: 14, color: BColors.darkGrey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Posted: ${item.postingDate}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: BColors.darkGrey,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BSizes.sm),
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
                       Icon(Iconsax.timer, size: 14, color: isOverdue ? BColors.error : BColors.darkGrey),
                       const SizedBox(width: 4),
                       Flexible(
                         child: Text(
                           'Due: ${item.dueDate}',
                           style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                 color: isOverdue ? BColors.error : BColors.darkGrey,
                                 fontWeight: FontWeight.bold,
                               ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                       if (isOverdue) ...[
                         const SizedBox(width: BSizes.xs),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: BColors.error,
                             borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
                           ),
                           child: Text(
                             BFormatter.formatDaysOverdue(daysPast),
                             style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                   color: BColors.white,
                                   fontWeight: FontWeight.bold,
                                 ),
                           ),
                         ),
                       ],
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
