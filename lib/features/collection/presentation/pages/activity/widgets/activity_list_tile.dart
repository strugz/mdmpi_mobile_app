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
    this.onLongPress,
    this.onInfoTap,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  final CollectionItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onInfoTap;
  final bool isSelected;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    final daysPast = item.daysPastDue;
    final isOverdue = item.isOverdue;
    // compute trimmed values here so they are not declared inside the widget
    // collection literal (declaring variables inside a list literal causes
    // a parse error). Use these when deciding whether to show the second
    // status badge.
    final lastOutcome = item.lastOutcome?.trim() ?? '';
    final status = item.status.trim();
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
        child: Container(
        margin: const EdgeInsets.only(bottom: BSizes.sm),
        padding: const EdgeInsets.all(BSizes.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? BColors.primary.withOpacity(0.05)
              : (isOverdue
                  ? BColors.error.withOpacity(0.06)
                  : (dark ? BColors.darkerGrey.withValues(alpha: 0.3) : BColors.white)),
          borderRadius: BorderRadius.circular(BSizes.cardRadiusMd),
          border: Border.all(
            color: isSelected ? BColors.primary : (dark ? Colors.transparent : BColors.grey),
            width: isSelected ? 2 : 1,
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
        child: Stack(
          children: [
            Column(
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
                            item.client.name,
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
                    if (!isSelectionMode)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(context, item.status),
                          // Only show the second badge when lastOutcome is present and
                          // different from the main status to avoid duplicate badges
                          // (e.g. both being "Collected"). Comparison is
                          // case-insensitive and trimmed.
                          if (lastOutcome.isNotEmpty && lastOutcome.toLowerCase() != status.toLowerCase()) ...[
                            const SizedBox(width: BSizes.xs),
                            _buildStatusBadge(context, item.lastOutcome!),
                          ],
                          if (onInfoTap != null) ...[
                            const SizedBox(width: BSizes.xs),
                            IconButton(
                              onPressed: onInfoTap,
                              icon: const Icon(Iconsax.info_circle, color: BColors.primary, size: 20),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
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
                              'Invoice Date: ${item.postingDate}',
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: BColors.error,
                          borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
                        ),
                        child: Text(
                          BFormatter.formatDaysOverdue(daysPast),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: BColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (isSelectionMode)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  isSelected ? Iconsax.tick_circle5 : Iconsax.add_circle,
                  color: isSelected ? BColors.primary : BColors.darkGrey,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    if (status.isEmpty) return const SizedBox.shrink();
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
