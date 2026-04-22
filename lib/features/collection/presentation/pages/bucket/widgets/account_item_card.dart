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
  final VoidCallback onTap;

  const AccountItemCard({
    super.key,
    required this.client,
    required this.invoiceCount,
    required this.totalAmount,
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
                  child: Text(
                    client.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Iconsax.arrow_right_3, size: 18, color: BColors.darkGrey),
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
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoices',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      '$invoiceCount pending',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
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
