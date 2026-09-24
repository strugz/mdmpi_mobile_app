import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';

/// Every status badge draws its label in the status colour on a light tint of
/// that same colour. An unmapped status used to get a near-white colour, so
/// "Advanced Payment" and "Advanced Payment Applied" on the calendar were
/// white text on white. These pin legibility, not particular hues.

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// The badge's text colour against the tint it sits on (10% over white), as
/// ActivityStatusBadge and the other tinted pills draw it.
double _tintedContrast(String status) {
  final c = CollectionStatusColors.colorFor(status);
  final tint = Color.alphaBlend(c.withValues(alpha: 0.12), Colors.white);
  return _contrast(c, tint);
}

void main() {
  const shown = [
    ...CollectionStatusColors.allStatuses,
    CollectionStatusColors.statusAdvance,
    CollectionStatusColors.statusAdvanceApplied,
    // Anything the map does not know — a new defer reason, a server status.
    'Office Closed',
    'Reconciliation Refused to Pay',
  ];

  for (final status in shown) {
    test('"$status" is legible as a tinted badge', () {
      expect(_tintedContrast(status), greaterThanOrEqualTo(3.0),
          reason: 'UI text and icons need at least 3:1');
    });

    test('"$status" is legible as a solid badge', () {
      final (bg, fg) = CollectionStatusColors.colorsFor(status);
      expect(_contrast(fg, bg), greaterThanOrEqualTo(3.0));
    });
  }

  test('advances read as float, applied advances as collected', () {
    expect(CollectionStatusColors.colorFor('Advanced Payment'),
        CollectionStatusColors.colorFor(CollectionStatusColors.statusPartial),
        reason: 'the amber of the home Advanced Payment tile');
    expect(
        CollectionStatusColors.colorFor('Advanced Payment Applied'),
        CollectionStatusColors.colorFor(
            CollectionStatusColors.statusCollected));
  });
}
