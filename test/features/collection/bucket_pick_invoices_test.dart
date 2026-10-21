import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/bucket/collection_account_invoices_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Reconciled invoices are pickable by invoice (update checklist item 24):
/// on the account's bucket page the collector can take only some of its
/// invoices, reconciled ones among them, and leave the rest in the bucket.

class _Tracker extends ReconciliationRepository {
  final acquired = <String>[];

  @override
  Future<Result<int>> acquireCasesFor(String clientCode) async {
    acquired.add(clientCode);
    return Result.success(1);
  }

  @override
  Future<Result<int>> openMissingCases(List<dynamic> marked) async =>
      Result.success(0);
}

class _Stub extends CollectionActivityController {
  final claimed = <String>[];
  final accounts = <String>[];

  @override
  Set<String> endedReconInvoiceIds() => const {};

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> claimItemsByIds(List<String> ids,
      {void Function(int done, int total)? onProgress}) async {
    claimed.addAll(ids);
    bucketItems.removeWhere((i) => ids.contains(i.id));
  }

  @override
  Future<void> claimAccount(String clientId) async => accounts.add(clientId);
}

final _amka = ClientModel(
    id: 'NLN-1',
    code: 'NLN-1',
    name: 'Amka Trading',
    address: '',
    contact: '',
    emailAddress: '');

CollectionItemModel _invoice(String id, double due, {String status = ''}) =>
    CollectionItemModel(
        id: id,
        client: _amka,
        toBeCollected: due,
        status: status,
        dueDate: '2999-01-01');

/// The success snackbar runs on a timer; let it finish so the next test
/// starts clean.
Future<void> _snackbarGone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  late _Tracker tracker;
  late _Stub c;

  setUp(() {
    tracker = Get.put<ReconciliationRepository>(_Tracker()) as _Tracker;
    c = Get.put<CollectionActivityController>(_Stub()) as _Stub;
    c.startAggregateTracking();
    c.masterAccountList.assignAll([_amka]);
    c.bucketItems.assignAll([
      _invoice('a1', 100),
      _invoice('r1', 50, status: 'Reconciliation'),
      _invoice('r2', 70, status: 'Reconciliation'),
      _invoice('p0', 0),
    ]);
  });

  tearDown(Get.reset);

  group('claimInvoices', () {
    test('takes only the picked reconciled invoice, with its case', () async {
      expect(await c.claimInvoices(['r1']), 1);
      expect(c.claimed, ['r1']);
      expect(tracker.acquired, ['NLN-1'], reason: 'the case comes along');
      expect(c.bucketItems.map((i) => i.id), ['a1', 'r2', 'p0'],
          reason: 'the rest stay in the bucket');
    });

    test('an ordinary invoice alone leaves the case where it is', () async {
      expect(await c.claimInvoices(['a1']), 1);
      expect(c.claimed, ['a1']);
      expect(tracker.acquired, isEmpty);
    });

    test('paid-off or unknown invoices are not taken', () async {
      expect(await c.claimInvoices(['p0', 'zz']), 0);
      expect(c.claimed, isEmpty);
    });
  });

  group('the account page', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: CollectionAccountInvoicesScreen(client: _amka),
      ));
      await tester.pumpAndSettle();
    }

    String label(WidgetTester tester) => tester
        .widget<Text>(find.descendant(
            of: find.byKey(const ValueKey('bucket-acquire')),
            matching: find.byType(Text)))
        .data!;

    testWidgets('claims the whole account until invoices are picked',
        (tester) async {
      await pump(tester);
      expect(label(tester), 'Claim Account');
      await tester.tap(find.byKey(const ValueKey('bucket-acquire')));
      await tester.pumpAndSettle();
      expect(c.accounts, ['NLN-1']);
      expect(c.claimed, isEmpty);
      await _snackbarGone(tester);
    });

    testWidgets('a long press picks, a tap adds, the button takes the picks',
        (tester) async {
      await pump(tester);
      await tester.longPress(find.byKey(const ValueKey('bucket-invoice-r1')));
      await tester.pumpAndSettle();
      expect(label(tester), 'Claim 1 Invoice');

      await tester.tap(find.byKey(const ValueKey('bucket-invoice-a1')));
      await tester.pumpAndSettle();
      expect(label(tester), 'Claim 2 Invoices');

      await tester.tap(find.byKey(const ValueKey('bucket-acquire')));
      await tester.pumpAndSettle();
      expect(c.claimed.toSet(), {'r1', 'a1'});
      expect(c.accounts, isEmpty, reason: 'not the whole account');
      await _snackbarGone(tester);
    });

    testWidgets('Clear goes back to the whole account', (tester) async {
      await pump(tester);
      await tester.longPress(find.byKey(const ValueKey('bucket-invoice-r1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bucket-pick-clear')));
      await tester.pumpAndSettle();
      expect(label(tester), 'Claim Account');
    });
  });
}
