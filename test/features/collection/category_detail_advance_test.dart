import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';

/// The Advanced Payment list. It shipped with a raw ISO stamp, an orange bar,
/// and a 32pt "Assign" button whose label the theme's padding pushed out of
/// view. These pin the redesign: the action says what it does and can be
/// read, the date is a date, the float is totalled, and nothing overflows on
/// a narrow phone at a larger font.

class _Activity extends CollectionActivityController {
  @override
  void onInit() {}
}

Map<String, dynamic> _advance({
  String id = 'AP-1',
  double amount = 750000,
  String clientName = 'Antipolo Doctors Hospital',
  String remarks = '',
}) =>
    {
      'id': id,
      // Not in masterAccountList: the card must fall back to the stored name.
      'clientId': 'C-$id',
      'clientName': clientName,
      'amount': amount,
      'remarks': remarks,
      'date': '2026-09-24T07:19:53.266764',
      'collectorName': 'Jay',
    };

Future<void> _pump(WidgetTester tester, List<Map<String, dynamic>> advances,
    {double scale = 1.0}) async {
  final activity = _Activity();
  Get.put<CollectionActivityController>(activity);
  activity.unassignedAdvancedPayments.assignAll(advances);

  await tester.pumpWidget(GetMaterialApp(
    theme: BCollectionTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
          size: const Size(360, 800), textScaler: TextScaler.linear(scale)),
      child: const CategoryDetailScreen(
          title: 'Advanced Payment', color: BCollectionColors.warning),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('the action can be read and says what it does', (tester) async {
    await _pump(tester, [_advance()]);

    final label = find.text('Apply to invoice');
    expect(label.hitTestable(), findsOneWidget);
    final button = find.ancestor(
        of: label,
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(40),
        reason: 'the 32pt button clipped its own label');
    expect(tester.getSize(label).height, greaterThan(0));
    expect(find.text('Assign'), findsNothing);
  });

  testWidgets('the date reads as a date and the account is named',
      (tester) async {
    await _pump(tester, [_advance()]);

    expect(find.text('Received Sep 24, 2026 07:19 AM'), findsOneWidget);
    expect(find.textContaining('T07:19'), findsNothing);
    expect(find.text('Antipolo Doctors Hospital'), findsOneWidget,
        reason: 'an account missing from the list used to print "N/A"');
    expect(find.text('₱750,000.00'), findsOneWidget);
  });

  testWidgets('the header totals the float', (tester) async {
    await _pump(tester,
        [_advance(), _advance(id: 'AP-2', amount: 50000, clientName: 'Bicol')]);

    expect(find.text('Awaiting an invoice'), findsOneWidget);
    expect(
        find.text('2 payments · ₱800,000.00 float, not yet in '
            'Collected this Month'),
        findsOneWidget);
    expect(find.text('Float · awaiting invoice'), findsNWidgets(2));
  });

  testWidgets('the bar is the Collection navy, not the category colour',
      (tester) async {
    await _pump(tester, [_advance()]);
    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.backgroundColor, isNull,
        reason: 'the theme supplies the navy bar');
  });

  testWidgets('with none waiting, it says what an advance is', (tester) async {
    await _pump(tester, []);
    expect(find.text('No advanced payments waiting'), findsOneWidget);
  });

  group('the Apply sheet', () {
    // A 360×800 phone with a 48pt gesture bar, as the window itself reports
    // it: the sheet is its own route and reads the window, not the page.
    const navBar = 48.0;
    Future<void> openSheet(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.padding = const FakeViewPadding(bottom: navBar);
      tester.view.viewPadding = const FakeViewPadding(bottom: navBar);
      addTearDown(tester.view.reset);

      final activity = _Activity();
      Get.put<CollectionActivityController>(activity);
      activity.unassignedAdvancedPayments.assignAll([_advance()]);
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: const CategoryDetailScreen(
            title: 'Advanced Payment', color: BCollectionColors.warning),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply to invoice'));
      await tester.pumpAndSettle();
    }

    Finder button(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

    testWidgets('keeps its actions clear of the gesture bar', (tester) async {
      await openSheet(tester);

      expect(tester.takeException(), isNull);
      for (final label in ['Cancel', 'Apply']) {
        final rect = tester.getRect(button(label));
        expect(rect.bottom, lessThanOrEqualTo(800 - navBar),
            reason: '$label sat on the gesture bar');
        expect(rect.height, greaterThanOrEqualTo(40));
      }
      expect(find.text('Assign'), findsNothing);
    });

    testWidgets('prefills the amount as money and names the month',
        (tester) async {
      await openSheet(tester);

      final amount = tester.widget<TextFormField>(
          find.byKey(const ValueKey('advance-amount-due')));
      expect(amount.controller!.text, '750,000.00',
          reason: 'it was prefilled as "750000.0"');

      final month = DateFormat('MMMM yyyy').format(DateTime.now());
      expect(
          find.text("Counts in $month's Collected this Month"), findsOneWidget);
    });

    testWidgets('asks for what is missing instead of applying', (tester) async {
      await openSheet(tester);

      await tester.tap(button('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the invoice number'), findsOneWidget);
      expect(find.text('Choose the due date'), findsOneWidget);
      expect(
          Get.find<CollectionActivityController>().unassignedAdvancedPayments,
          hasLength(1),
          reason: 'nothing was applied');
    });
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('a long name and a remark fit a narrow phone at $scale',
        (tester) async {
      await _pump(
        tester,
        [
          _advance(
            clientName: 'Accusure Medical Enterprises Incorporated Hospital',
            amount: 12345678.9,
            remarks: 'Advance for the October supply order, check to follow',
          ),
        ],
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
