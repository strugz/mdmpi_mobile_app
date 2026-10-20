import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/activity_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/quick_fill_chip.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// A Pre-Collection records what the next scheduled collection will bring:
/// the amount, and the check when there is one (its date is when to
/// collect). It settles nothing: the balance stays, nothing counts as
/// collected, and the server creates no payment for it.

const _pre = CollectionStatusColors.statusPreCollection;

final _client = ClientModel(
    id: 'C1',
    code: 'NLN-1',
    name: 'Accusure Medical Enterprises',
    address: '',
    contact: '',
    emailAddress: '');

CollectionItemModel _invoice(String id, double due,
        {List<CollectionHistoryModel> history = const []}) =>
    CollectionItemModel(
      id: id,
      client: _client,
      bpCode: 'NLN-1',
      toBeCollected: due,
      assignedAt: '2026-10-20T08:00:00',
      history: history,
    );

class _Repo extends CollectionRepository {
  final saved = <({String id, String status, double? amount, String? check})>[];
  final batched = <({List<String> ids, Map<String, double> amounts})>[];

  @override
  String get collectorName => 'Jay';

  @override
  Future<void> saveActivity({
    required String id,
    required String status,
    required String remarks,
    double? totalCollected,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    bool silent = false,
  }) async =>
      saved.add((
        id: id,
        status: status,
        amount: totalCollected,
        check: checkNumber,
      ));

  @override
  Future<void> saveBatchActivity({
    required List<String> ids,
    required Map<String, String> statuses,
    required Map<String, String> remarks,
    required Map<String, double> amounts,
    double totalAmountReceived = 0,
    String? bankName,
    String? checkNumber,
    String? checkDate,
    String? purposeOfVisit,
    bool silent = false,
  }) async =>
      batched.add((ids: ids, amounts: amounts));
}

class _Activity extends CollectionActivityController {
  _Activity(this._repo);
  final _Repo _repo;

  @override
  // ignore: must_call_super
  void onInit() => repository = _repo;
}

void main() {
  tearDown(Get.reset);

  group('the rule', () {
    test('a Pre-Collection amount never comes off the balance', () {
      expect(CollectionOutcome.isPreCollection(_pre), isTrue);
      expect(CollectionOutcome.appliedAmount(_pre, 50000), 0);
      expect(
          CollectionOutcome.appliedAmount(
              CollectionStatusColors.statusPartial, 250),
          250);
    });

    test('nor counts as collected', () {
      expect(CollectionOutcome.countsAsCollected(_pre, kind: 'INVOICE'),
          isFalse);
      expect(
          CollectionOutcome.countsAsCollected(
              CollectionStatusColors.statusCollected,
              kind: 'INVOICE'),
          isTrue);
    });
  });

  group('saving', () {
    test('keeps the amount and check on the record, the balance as it was',
        () async {
      final repo = _Repo();
      final c = Get.put<CollectionActivityController>(_Activity(repo))
          as _Activity;
      c.activityItems.assignAll([_invoice('PC1', 50000)]);

      await c.saveActivity(
        id: 'PC1',
        status: _pre,
        remarks: _pre,
        totalCollected: 50000,
        bankName: 'BDO',
        checkNumber: '1234567',
        checkDate: '10-25-2026',
        purposeOfVisit: _pre,
      );

      final item = c.activityItems.single;
      expect(item.toBeCollected, 50000, reason: 'not settled');
      expect(item.totalCollected, 0);
      expect(item.lastOutcome, _pre);
      expect(c.bucketItems, isEmpty, reason: 'still the collector\'s');
      final h = item.history.last;
      expect(h.status, _pre);
      expect(h.totalCollected, 50000, reason: 'the amount to collect');
      expect(h.checkNumber, '1234567');
      expect(repo.saved.single.amount, 50000,
          reason: 'uploaded, for the server to keep as information');
    });

    test('a real collection still comes off the balance', () async {
      final repo = _Repo();
      final c = Get.put<CollectionActivityController>(_Activity(repo))
          as _Activity;
      c.activityItems.assignAll([_invoice('C1', 1000)]);

      await c.saveActivity(
          id: 'C1',
          status: CollectionStatusColors.statusPartial,
          remarks: 'x',
          totalCollected: 250);

      expect(c.activityItems.single.toBeCollected, 750);
    });

    test('a batch row marked Pre-Collection keeps its balance', () async {
      final repo = _Repo();
      final c = Get.put<CollectionActivityController>(_Activity(repo))
          as _Activity;
      c.activityItems
          .assignAll([_invoice('B1', 8000), _invoice('B2', 2000)]);

      await c.saveBatchActivity(
        ids: ['B1', 'B2'],
        statuses: {'B1': _pre, 'B2': CollectionStatusColors.statusCollected},
        remarks: const {},
        amounts: {'B1': 8000, 'B2': 2000},
        totalAmountReceived: 10000,
      );

      final b1 = c.activityItems.firstWhere((i) => i.id == 'B1');
      expect(b1.toBeCollected, 8000);
      expect(b1.history.last.totalCollected, 8000);
      expect(c.bucketItems.map((i) => i.id), ['B2'],
          reason: 'the collected one is settled and released');
    });
  });

  group('the engagement form', () {
    Widget host(CollectionItemModel item) =>
        GetMaterialApp(home: ActivityDetailScreen(item: item));

    Future<void> pickPre(WidgetTester tester) async {
      final chip = find.byWidgetPredicate(
          (w) => w is BQuickFillChip && w.label.startsWith(_pre));
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    testWidgets('Pre-Collection says the amount is for the next collection',
        (tester) async {
      await tester.pumpWidget(host(_invoice('PC1', 1000)));
      await tester.pumpAndSettle();
      await pickPre(tester);
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pumpAndSettle();

      expect(find.text('Amount to collect'), findsOneWidget);
      expect(find.byKey(const ValueKey('pre-collection-note')), findsOneWidget);
      expect(find.text('Settles this invoice in full'), findsNothing);
    });

    testWidgets('typing the amount first does not drop Pre-Collection',
        (tester) async {
      await tester.pumpWidget(host(_invoice('PC1', 1000)));
      await tester.pumpAndSettle();
      await pickPre(tester);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();

      final chip = tester.widget<BQuickFillChip>(find.byWidgetPredicate(
          (w) => w is BQuickFillChip && w.label.startsWith(_pre)));
      expect(chip.selected, isTrue);
    });
  });

  group('the Pre-Collection list', () {
    CollectionHistoryModel pre(
            {double amount = 0,
            String? bank,
            String? no,
            String? date}) =>
        CollectionHistoryModel(
          date: '2026-10-20',
          collectorName: 'Jay',
          status: _pre,
          totalCollected: amount,
          bankName: bank,
          checkNumber: no,
          checkDate: date,
        );

    test('shows the next collection: amount and check', () {
      expect(
          preCollectionDetails(_invoice('PC1', 50000, history: [
            pre(amount: 50000, bank: 'BDO', no: '1234567', date: '10-25-2026'),
          ])),
          'Next collection: ₱50,000.00 · Check BDO 1234567, dated 10-25-2026');
    });

    test('the latest Pre-Collection wins; cash shows the amount only', () {
      expect(
          preCollectionDetails(_invoice('PC1', 900, history: [
            pre(amount: 100, bank: 'BPI', no: '1'),
            pre(amount: 900),
          ])),
          'Next collection: ₱900.00');
    });

    test('nothing recorded: no line', () {
      expect(preCollectionDetails(_invoice('PC1', 1, history: [pre()])), '');
      expect(preCollectionDetails(_invoice('PC1', 1)), '');
    });
  });
}
