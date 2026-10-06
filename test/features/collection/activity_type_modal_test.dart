import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/app_routes.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/common/widgets/animations/pressable_scale.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/activity_type_modal.dart';

/// Opens the sheet from a button, the way the calendar does.
Widget _host() {
  return MaterialApp(
    theme: BCollectionTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => ActivityTypeModal.show(context),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('titles the sheet as the button that opened it and lists the '
      'four engagement types', (tester) async {
    await tester.pumpWidget(_host());
    await _open(tester);

    expect(find.text('Add field engagement'), findsOneWidget);
    for (final type in ActivityTypeModal.types) {
      expect(find.text(type.title), findsOneWidget);
      expect(find.text(type.subtitle), findsOneWidget);
    }
    // Every row presses down under the finger, like the defer sheet's.
    expect(find.byType(BPressableScale),
        findsNWidgets(ActivityTypeModal.types.length));
  });

  testWidgets('rows borrow the card icon and colour of their status',
      (tester) async {
    await tester.pumpWidget(_host());
    await _open(tester);

    final deposit = find.byIcon(
        CollectionStatusColors.iconFor(CollectionStatusColors.statusDeposit));
    expect(deposit, findsOneWidget);
    expect(tester.widget<Icon>(deposit).color,
        CollectionStatusColors.colorFor(CollectionStatusColors.statusDeposit));

    // No two rows share a hue: CWT and Advanced Payment were both amber.
    final colours = ActivityTypeModal.types.map((t) => t.color).toSet();
    expect(colours.length, ActivityTypeModal.types.length);
  });

  testWidgets('the close control dismisses the sheet', (tester) async {
    await tester.pumpWidget(_host());
    await _open(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Add field engagement'), findsNothing);
  });

  test('every engagement type opens a named route that the app registers',
      () {
    final registered = AppRoutes.pages.map((p) => p.name).toSet();
    for (final type in ActivityTypeModal.types) {
      final route = ActivityTypeModal.routeFor(type.title);
      expect(route, startsWith('/collection/engagement/'),
          reason: '${type.title} should open an engagement form route');
      expect(registered, contains(route),
          reason: '$route has a BRoutes constant but no GetPage');
    }
    expect(ActivityTypeModal.routeFor(CollectionStatusColors.statusDeposit),
        BRoutes.collectionDepositForm);
    expect(
        ActivityTypeModal.routeFor(CollectionStatusColors.statusCWTPickup),
        BRoutes.collectionCwtPickupForm);
    expect(
        ActivityTypeModal.routeFor(
            CollectionStatusColors.statusReconciliation),
        BRoutes.collectionReconciliationForm);
    expect(ActivityTypeModal.routeFor('anything else'),
        BRoutes.collectionAdvancedPaymentForm);
  });
}
