import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import '../deposit_form.dart';
import '../cwt_pickup_form.dart';
import '../reconciliation_form.dart';

class ActivityTypeModal extends StatelessWidget {
  const ActivityTypeModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BSizes.defaultSpace),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Activity Type',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Iconsax.close_circle),
              ),
            ],
          ),
          const SizedBox(height: BSizes.spaceBtwSections),
          
          _buildOption(
            context,
            title: 'Deposit',
            subtitle: 'Record a bank deposit for collections',
            icon: Iconsax.bank,
            color: Colors.blue,
            onTap: () {
              Get.back();
              Get.to(() => const DepositFormScreen());
            },
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          
          _buildOption(
            context,
            title: 'CWT Pick-up',
            subtitle: 'Record Creditable Withholding Tax pick-up',
            icon: Iconsax.document_text,
            color: Colors.orange,
            onTap: () {
              Get.back();
              Get.to(() => const CWTPickupFormScreen());
            },
          ),
          const SizedBox(height: BSizes.spaceBtwItems),
          
          _buildOption(
            context,
            title: 'Reconciliation',
            subtitle: 'Account reconciliation activities',
            icon: Iconsax.status_up,
            color: Colors.purple,
            onTap: () {
              Get.back();
              Get.to(() => const ReconciliationFormScreen());
            },
          ),
          const SizedBox(height: BSizes.spaceBtwSections),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Iconsax.arrow_right_3, size: 18),
      contentPadding: EdgeInsets.zero,
    );
  }
}
