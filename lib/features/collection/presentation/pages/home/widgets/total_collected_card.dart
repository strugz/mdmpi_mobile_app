import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';

/// Feature-scoped card showing Total Collected vs Target for the current month.
class TotalCollectedCard extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;

  const TotalCollectedCard({super.key, this.color = Colors.green, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is registered. If GeneralBindings wasn't applied for
    // this route, lazily register the controller so Get.find() will succeed.
    if (!Get.isRegistered<TotalCollectedController>()) {
      Get.lazyPut(() => TotalCollectedController(), fenix: true);
    }
    final controller = Get.find<TotalCollectedController>();

    final backgroundColor = color.withAlpha((0.08 * 255).round());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BSizes.defaultSpace / 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Obx(() {
          final total = controller.monthlyTotal;
          final target = controller.targetAmount.value;

          return Row(
            children: [
              Icon(Iconsax.money, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Collected this Month', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 6),
                    Text(
                      BFormatter.formatPesoCurrency(total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: BSizes.fontSizeLg * 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Target column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Target', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    target > 0 ? BFormatter.formatPesoCurrency(target) : '—',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}



