import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

/// A single activity entry tile used in the Activity list.
///
/// Displays an icon, title, subtitle, time, and a status badge.
class ActivityListTile extends StatelessWidget {
  const ActivityListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.icon,
    this.amount,
    this.onTap,
  });

  /// Primary label (e.g. client name).
  final String title;

  /// Secondary info (e.g. "BDO • CHQ #001234").
  final String subtitle;

  /// Formatted time string (e.g. "2026-03-03 10:30").
  final String time;

  /// Status text shown in the badge (e.g. "Completed", "Pending", "Overdue").
  final String status;

  /// Badge background color.
  final Color statusColor;

  /// Leading icon for the activity type.
  final IconData icon;

  /// Formatted collection amount (e.g. "₱25,000.00"). Optional.
  final String? amount;

  /// Optional tap callback.
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
        child: Row(
          children: [
            /// Leading icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
              ),
              child: Icon(icon, color: statusColor, size: BSizes.iconMd),
            ),

            const SizedBox(width: BSizes.spaceBtwItemsLight),

            /// Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BSizes.xxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BColors.darkGrey,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (amount != null && amount!.isNotEmpty) ...[
                    const SizedBox(height: BSizes.xxs),
                    Text(
                      amount!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: BColors.primary,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: BSizes.sm),

            /// Time + status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BColors.darkGrey,
                      ),
                ),
                const SizedBox(height: BSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BSizes.sm,
                    vertical: BSizes.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BSizes.borderRadiusSm),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}







