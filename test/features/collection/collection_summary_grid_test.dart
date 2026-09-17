import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/collection_summary_grid.dart';

/// The four counts were pages of a carousel: 118pt of screen to show one
/// integer, the other three behind swipes. They are a scoreboard, so they are
/// read at a glance now — all four, two by two, for about the height one page
/// used to take.

List<CollectionSummaryStat> _stats({void Function(String)? onTap}) => [
      CollectionSummaryStat(
        title: 'Settled',
        value: '1',
        icon: Iconsax.tick_circle,
        color: BCollectionColors.success,
        onTap: () => onTap?.call('Settled'),
      ),
      CollectionSummaryStat(
        title: 'Due Date',
        value: '3767',
        icon: Iconsax.timer,
        color: BCollectionColors.danger,
        onTap: () => onTap?.call('Due Date'),
      ),
      CollectionSummaryStat(
        title: 'Reconciliation',
        value: '0',
        icon: Iconsax.status_up,
        color: BCollectionColors.reconcile,
        onTap: () => onTap?.call('Reconciliation'),
      ),
      CollectionSummaryStat(
        title: 'Advanced Payment',
        value: '0',
        icon: Iconsax.card_send,
        color: BCollectionColors.warning,
        onTap: () => onTap?.call('Advanced Payment'),
      ),
    ];

/// The dashboard lays this out inside a SingleChildScrollView, where the
/// vertical constraint is unbounded and a stretching Row fails layout.
Widget _inUnboundedColumn(Widget child, {double textScale = 1}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
            ]),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows all four counts at once', (tester) async {
    await tester
        .pumpWidget(_inUnboundedColumn(CollectionSummaryGrid(stats: _stats())));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final title in [
      'Settled',
      'Due Date',
      'Reconciliation',
      'Advanced Payment',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('3767'), findsOneWidget);
    // No paging chrome: a scoreboard is not browsed.
    expect(find.byType(PageView), findsNothing);
  });

  // The carousel spent 118pt on one number. Four in about that is the trade
  // this layout was chosen for, so it is worth holding onto.
  testWidgets('four counts cost about what one page used to', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester
        .pumpWidget(_inUnboundedColumn(CollectionSummaryGrid(stats: _stats())));
    await tester.pumpAndSettle();

    final height = tester.getSize(find.byType(CollectionSummaryGrid)).height;
    expect(height, lessThan(140),
        reason: 'four counts in roughly the 118pt one page took');
  });

  testWidgets('the two cells in a row share one height', (tester) async {
    await tester
        .pumpWidget(_inUnboundedColumn(CollectionSummaryGrid(stats: _stats())));
    await tester.pumpAndSettle();

    // "Advanced Payment" is the label most likely to wrap and unbalance a row.
    final left = tester.getSize(find
        .ancestor(
          of: find.text('Reconciliation'),
          matching: find.byType(Container),
        )
        .first);
    final right = tester.getSize(find
        .ancestor(
          of: find.text('Advanced Payment'),
          matching: find.byType(Container),
        )
        .first);
    expect(left.height, right.height);
  });

  testWidgets('each count opens its own category', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(_inUnboundedColumn(
        CollectionSummaryGrid(stats: _stats(onTap: opened.add))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reconciliation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Due Date'));
    await tester.pumpAndSettle();

    expect(opened, ['Reconciliation', 'Due Date']);
  });

  testWidgets('survives the dashboard text-scale clamp', (tester) async {
    await tester.pumpWidget(_inUnboundedColumn(
      CollectionSummaryGrid(stats: _stats()),
      textScale: 1.15,
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Advanced Payment'), findsOneWidget);
  });

  testWidgets('an odd count leaves a hole, not a stretched cell',
      (tester) async {
    await tester.pumpWidget(_inUnboundedColumn(
        CollectionSummaryGrid(stats: _stats().take(3).toList())));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final third = tester.getSize(find
        .ancestor(
          of: find.text('Reconciliation'),
          matching: find.byType(Container),
        )
        .first);
    final first = tester.getSize(find
        .ancestor(
          of: find.text('Settled'),
          matching: find.byType(Container),
        )
        .first);
    expect(third.width, first.width,
        reason: 'the lone cell keeps its column width');
  });
}
