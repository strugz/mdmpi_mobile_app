import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/invoice_search.dart';

/// PO | SI over an account's invoices: P.O. groups that open to their SIs,
/// or a flat SI list with the P.O. gone.
class InvoiceViewToggle extends StatelessWidget {
  const InvoiceViewToggle(
      {super.key, required this.mode, required this.onChanged});

  final InvoiceViewMode mode;
  final ValueChanged<InvoiceViewMode> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            BSizes.defaultSpace, BSizes.xs, BSizes.defaultSpace, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<InvoiceViewMode>(
            key: const ValueKey('invoice-view-toggle'),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final m in InvoiceViewMode.values)
                ButtonSegment(
                  value: m,
                  label: Text(m.label, key: ValueKey('invoice-view-${m.name}')),
                ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      );
}
