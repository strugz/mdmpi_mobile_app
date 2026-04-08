import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// A single activity entry tile used in the Activity list.
///
/// Displays an icon, title, subtitle, time, and four status badges.
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
    
    // Use coreStatus for primary theme
    final primaryColor = CollectionStatusColors.colorFor(item.coreStatus);
    final primaryIcon = CollectionStatusColors.iconFor(item.coreStatus);

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
          children: [
            Row(
              children: [
                /// Leading icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                  ),
                  child: Icon(primaryIcon, color: primaryColor, size: BSizes.iconMd),
                ),

                const SizedBox(width: BSizes.spaceBtwItemsLight),

                /// Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.client.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: BSizes.xxs),
                      Text(
                        '${item.bankName} • ${item.documentReferences.isNotEmpty ? item.documentReferences.first : '—'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BColors.darkGrey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: BSizes.sm),

                /// Time + Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.assignedAt,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: BColors.darkGrey,
                          ),
                    ),
                    const SizedBox(height: BSizes.xs),
                    Text(
                      BFormatter.formatPesoCurrency(item.amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: BColors.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: BSizes.spaceBtwItems),
            
            /// Four Status Badges
            Row(
              children: [
                _buildStatusBadge(context, item.coreStatus),
                const SizedBox(width: BSizes.xs),
                _buildStatusBadge(context, item.delayStatus),
                const SizedBox(width: BSizes.xs),
                _buildStatusBadge(context, item.outcomeStatus),
                const SizedBox(width: BSizes.xs),
                _buildStatusBadge(context, item.administrativeStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    if (status == CollectionStatusColors.statusOnSchedule || status == CollectionStatusColors.statusNone) {
      return const SizedBox.shrink();
    }
    
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
