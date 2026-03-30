import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
// ...existing imports...
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';

/// Row with Capture / Attach File actions used by `BItemScanner`.
class ScannerActionRow extends StatelessWidget {
  const ScannerActionRow({super.key, required this.controller});

  final StandardDeliveryController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: controller.pickAndAnalyzeFromCamera,
          icon: const Icon(Iconsax.camera),
          label: const Text('Capture'),
        ),
        const SizedBox(width: BSizes.sm),
        OutlinedButton.icon(
          onPressed: controller.pickAndAnalyzeFromFile,
          icon: const Icon(Iconsax.folder_2),
          label: const Text('Attach File'),
        ),
      ],
    );
  }
}

/// Small centered analyzing/loading indicator used while files are processed.
class AnalyzingIndicator extends StatelessWidget {
  const AnalyzingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSizes.sm),
      child: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

