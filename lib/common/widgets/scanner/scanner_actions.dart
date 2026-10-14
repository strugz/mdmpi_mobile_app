import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// Capture / Attach File, the two ways into a document scanner: the
/// Logistics inventory scanner (`ScannedItemsScreen`) and the Collection
/// voucher scan. Null actions show the button disabled (while analysing).
class ScannerActionRow extends StatelessWidget {
  const ScannerActionRow({super.key, this.onCapture, this.onAttach});

  final VoidCallback? onCapture;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    // Wraps onto two lines on a narrow screen instead of overflowing.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: BSizes.sm,
      runSpacing: BSizes.xs,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('scanner-capture'),
          onPressed: onCapture,
          icon: const Icon(Iconsax.camera),
          label: const Text('Capture'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('scanner-attach'),
          onPressed: onAttach,
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
