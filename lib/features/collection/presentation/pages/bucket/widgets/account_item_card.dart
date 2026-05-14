import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

class AccountItemCard extends StatelessWidget {
  final ClientModel client;
  final int invoiceCount;
  final double totalAmount;
  final double totalCollected;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;
  final VoidCallback? onClaimTap; // Added optional claim tap

  const AccountItemCard({
    super.key,
    required this.client,
    required this.invoiceCount,
    required this.totalAmount,
    this.totalCollected = 0.0,
    required this.onTap,
    required this.onInfoTap,
    this.onClaimTap,
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
          border: Border.all(color: BColors.grey),
          boxShadow: [
            BoxShadow(
              color: BColors.black.withOpacity(0.05),
              blurRadius: 5,
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
                        client.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Code: ${client.code}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: BColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onInfoTap,
                  icon: const Icon(Iconsax.info_circle, size: 22, color: BColors.primary),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: BSizes.xs),
            Row(
              children: [
                const Icon(Iconsax.location, size: 16, color: BColors.darkGrey),
                const SizedBox(width: BSizes.xs),
                Expanded(
                  child: Text(
                    client.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: BColors.darkGrey,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: BSizes.spaceBtwSections),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoices',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      '$invoiceCount invoices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (onClaimTap != null) ...[
                      const SizedBox(height: BSizes.md),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onClaimTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: BSizes.md),
                            side: const BorderSide(color: BColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(BSizes.borderRadiusMd),
                            ),
                          ),
                          child: Text(
                            'Claim Account',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: BColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Amount Due',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      currencyFormat.format(totalAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: BSizes.xs),
                    Text(
                      'Total Collected',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      currencyFormat.format(totalCollected),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: BColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
