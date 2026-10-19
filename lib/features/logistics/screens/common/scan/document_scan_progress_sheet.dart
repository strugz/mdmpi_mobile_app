import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';

/// The three parts of a scan while the photo is being read (plan §3). All
/// three come from the same on-device pass, so they tick together.
class DocumentScanProgress extends StatelessWidget {
  const DocumentScanProgress({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: BSizes.xs),
          child: Row(
            children: [
              const SizedBox(
                width: BSizes.iconSm,
                height: BSizes.iconSm,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: BSizes.md),
              Text(label),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.all(BSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reading the document…',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: BSizes.sm),
          row('Client'),
          row('References'),
          row('Items'),
        ],
      ),
    );
  }
}
