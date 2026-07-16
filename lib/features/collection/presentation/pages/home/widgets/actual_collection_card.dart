import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/total_collected_controller.dart';

class ActualCollectionCard extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;

  const ActualCollectionCard({super.key, this.color = Colors.indigo, this.onTap});

  @override
  Widget build(BuildContext context) {
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
          final actual = controller.actualCollectionTotal;
          final target = controller.targetAmount.value;

          return Row(
            children: [
              Icon(Iconsax.bank, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Actual Collection', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 6),
                    Text(
                      BFormatter.formatPesoCurrency(actual),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, 
                        fontSize: BSizes.fontSizeLg * 1.4,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
