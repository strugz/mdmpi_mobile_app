import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// A single activity entry tile used in the Activity list.
class ActivityListTile extends StatelessWidget {
  const ActivityListTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final CollectionItemModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: BSizes.sm),
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: dark ? BColors.darkerGrey.withValues(alpha: 0.3) : BColors.white,
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          border: Border.all(
            color: dark ? Colors.transparent : BColors.grey,
          ),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: BColors.darkGrey.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      BFormatter.formatPesoCurrency(
                        item.toBeCollected == 0 ? item.totalCollected : item.toBeCollected,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: item.toBeCollected == 0 ? BColors.success : BColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (item.toBeCollected == 0) ...[
                      const SizedBox(width: 4),
                      const Icon(Iconsax.tick_circle5, color: BColors.success, size: 18),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: BSizes.xs),

            Row(
              children: [
                const Icon(Iconsax.timer, size: 14, color: BColors.error),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Due: ${item.dueDate}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: BColors.error,
                          fontWeight: FontWeight.bold,
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
