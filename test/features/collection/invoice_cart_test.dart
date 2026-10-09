import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/invoice_search.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/activity_account_invoices_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/batch_activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/invoice_cart_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Meeting of 2026-10-07, items 1–2: the PO/SI switch, the cart on a claimed
/// account, and filling the cart from a scanned voucher.

class _Stub extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

final _client = ClientModel(
    id: '1',
    code: 'NLN-115',
    name: 'Accusure Medical',
    address: '',
    contact: '',
    emailAddress: '');

CollectionItemModel _inv(String id, double due, {String po = ''}) =>
    CollectionItemModel(
        id: id,
        client: _client,
        toBeCollected: due,
        poNumber: po,
        dueDate: '2999-01-01');

_Stub _seeded() {
  final c = Get.put<CollectionActivityController>(_Stub()) as _Stub;
  c.startAggregateTracking();
  c.masterAccountList.assignAll([_client]);
  c.activityItems.assignAll([
    _inv('700013390', 1000, po: 'PO-77'),
    _inv('700013391', 2000, po: 'PO-77'),
    _inv('97339', 500),
  ]);
  return c;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(
    theme: BCollectionTheme.light,
    home: CollectionActivityAccountInvoicesScreen(client: _client),
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  group('search follows the PO/SI switch', () {
    final item = _inv('700013390', 1, po: 'PO-77');

    test('the P.O. is searched only in PO mode', () {
      expect(invoiceMatchesSearch(item, 'po-77', InvoiceViewMode.po), isTrue);
      expect(invoiceMatchesSearch(item, 'po-77', InvoiceViewMode.si), isFalse);
      expect(invoiceMatchesSearch(item, '13390', InvoiceViewMode.si), isTrue);
      expect(invoiceMatchesSearch(item, '', InvoiceViewMode.si), isTrue);
    });

    test('an unknown stored mode reads as PO', () {
      expect(InvoiceViewMode.fromName('si'), InvoiceViewMode.si);
      expect(InvoiceViewMode.fromName(null), InvoiceViewMode.po);
    });
  });

  group('cart', () {
    test('items, total, and a paid-off invoice dropping out', () {
      final c = _seeded();
      c.addToCart(['700013390', '97339']);
      expect(c.isActivitySelectionMode.value, isTrue);
      expect(c.cartItems('1').map((i) => i.id), ['700013390', '97339']);
      expect(c.cartTotal('1'), 1500);

      c.activityItems[0] = _inv('700013390', 0, po: 'PO-77');
      expect(c.cartItems('1').map((i) => i.id), ['97339']);
    });

    test('Select All covers what is on screen, not what search hides', () {
      final c = _seeded();
      c.addToCart(['97339']);
      c.invoiceSearchQuery.value = '7000133';
      expect(c.isAllVisibleSelected('1'), isFalse);
      c.toggleSelectAllVisible('1');
      expect(c.selectedActivityInvoiceIds,
          {'97339', '700013390', '700013391'});
      c.toggleSelectAllVisible('1');
      expect(c.selectedActivityInvoiceIds, {'97339'},
          reason: 'the hidden one stays in the cart');
    });

    test('invoices from a voucher are marked, and leave with the cart', () {
      final c = _seeded();
      c.addFromVoucher(['700013390', '97339']);
      expect(c.voucherInvoiceIds, {'700013390', '97339'});
      c.removeFromCart('97339');
      expect(c.voucherInvoiceIds, {'700013390'});
      c.removeFromCart('700013390');
      expect(c.isActivitySelectionMode.value, isFalse);
      expect(c.voucherInvoiceIds, isEmpty);
    });
  });

  group('screen', () {
    testWidgets('PO groups by default; SI shows a flat list without P.O.',
        (tester) async {
      final c = _seeded();
      await _pump(tester);
      expect(find.byKey(const ValueKey('po-PO-77')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('invoice-view-si')));
      await tester.pumpAndSettle();
      expect(c.invoiceViewMode.value, InvoiceViewMode.si);
      expect(find.byKey(const ValueKey('po-PO-77')), findsNothing);
      expect(find.text('#700013391'), findsOneWidget);
      expect(find.text('Search SI'), findsOneWidget);
    });

    testWidgets('long-press starts the cart; the bar totals it; search stays',
        (tester) async {
      _seeded();
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('invoice-view-si')));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('#97339'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cart-bar')), findsOneWidget);
      expect(find.textContaining('1 in cart'), findsWidgets);
      expect(find.text('Search SI'), findsOneWidget,
          reason: 'search is how a long list is carted');

      await tester.tap(find.text('#700013391'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 in cart'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('cart-review')));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceCartScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('cart-item-97339')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      expect(find.byType(BatchActivityDetailScreen), findsOneWidget);
      expect(find.byType(InvoiceCartScreen), findsNothing,
          reason: 'replaced, so saving returns to the list');
    });

    testWidgets('selected invoices gather at the top, in a group that collapses',
        (tester) async {
      final c = _seeded();
      await _pump(tester);
      expect(find.byKey(const ValueKey('cart-group')), findsNothing);

      c.addToCart(['97339', '700013391']);
      await tester.pumpAndSettle();
      expect(find.text('Selected (2)'), findsOneWidget);
      final group = find.byKey(const ValueKey('cart-group'));
      expect(
          find.descendant(of: group, matching: find.text('#97339')),
          findsOneWidget);
      expect(
          find.descendant(of: group, matching: find.text('#700013391')),
          findsOneWidget);
      expect(find.text('#700013391'), findsOneWidget,
          reason: 'not listed twice');
      expect(tester.getTopLeft(group).dy,
          lessThan(tester.getTopLeft(find.text('#700013390')).dy),
          reason: 'the group is above the rest');

      await tester.tap(find.byKey(const ValueKey('cart-group-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('#97339'), findsNothing, reason: 'collapsed');
      expect(find.text('Selected (2)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cart-group-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#97339')); // untick: back to the rest
      await tester.pumpAndSettle();
      expect(find.text('Selected (1)'), findsOneWidget);
      expect(
          find.descendant(of: group, matching: find.text('#97339')),
          findsNothing);
      expect(find.text('#97339'), findsOneWidget);
    });

    testWidgets('the cart bar fits a narrow phone at large text', (tester) async {
      final c = _seeded();
      c.activityItems.add(_inv('700099001', 98765432.10));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(340, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
              size: Size(340, 700), textScaler: TextScaler.linear(1.3)),
          child: CollectionActivityAccountInvoicesScreen(client: _client),
        ),
      ));
      c.addToCart(['700013390', '700013391', '97339', '700099001']);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(find.text('4 selected'), findsOneWidget);
      final bar = tester.getRect(find.byKey(const ValueKey('cart-bar')));
      final button = tester.getRect(find.byKey(const ValueKey('cart-review')));
      expect(button.right, lessThanOrEqualTo(bar.right - 16),
          reason: 'the button keeps its margin from the screen edge');
    });

    testWidgets('a one-invoice checkout ends carting when its record closes',
        (tester) async {
      final c = _seeded();
      await _pump(tester);
      c.addToCart(['97339']);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-review')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-checkout')));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceCartScreen), findsNothing);
      Get.back();
      await tester.pumpAndSettle();
      expect(c.isActivitySelectionMode.value, isFalse);
      expect(c.selectedActivityInvoiceIds, isEmpty);
      expect(find.byKey(const ValueKey('cart-bar')), findsNothing);
    });

    testWidgets('removing the last invoice closes the cart', (tester) async {
      final c = _seeded();
      await _pump(tester);
      c.addToCart(['97339']);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-review')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cart-remove-97339')));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceCartScreen), findsNothing);
      expect(c.isActivitySelectionMode.value, isFalse);
    });
  });
}
