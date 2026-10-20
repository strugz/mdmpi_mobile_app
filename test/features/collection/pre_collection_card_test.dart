import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// The Pre-Collection card on Home (update checklist item 8): open invoices
/// whose last outcome is Pre-Collection, acquired or back in the bucket,
/// listed by account like Past Due.

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

ClientModel _client(String id, String name) => ClientModel(
    id: id, code: id, name: name, address: '', contact: '', emailAddress: '');

final _amka = _client('NCR-1', 'Amka Trading');
final _ace = _client('SLN-2', 'Ace Diagnostics Corp.');

CollectionItemModel _invoice(String id, ClientModel c,
        {double due = 1000,
        String? outcome = CollectionStatusColors.statusPreCollection,
        String status = '',
        String assignedAt = ''}) =>
    CollectionItemModel(
      id: id,
      client: c,
      bpCode: c.code,
      toBeCollected: due,
      lastOutcome: outcome,
      status: status,
      assignedAt: assignedAt,
    );

_Activity _seeded() {
  final c = Get.put<CollectionActivityController>(_Activity()) as _Activity;
  c.startAggregateTracking();
  c.masterAccountList.assignAll([_amka, _ace]);
  c.bucketItems.assignAll([
    _invoice('P1', _amka),
    // Paid since: no longer waiting to be collected.
    _invoice('P2', _amka, due: 0),
    // Marked for reconciliation: listed under Reconciliation instead.
    _invoice('P3', _amka, status: 'Reconciliation'),
    // A later outcome replaced it.
    _invoice('F1', _ace, outcome: CollectionStatusColors.statusFollowUp),
  ]);
  c.activityItems.assignAll([
    // Acquired: still Pre-Collection.
    _invoice('P4', _ace, assignedAt: '2026-10-20T08:00:00'),
  ]);
  return c;
}

void main() {
  tearDown(Get.reset);

  test('counts open Pre-Collection invoices, acquired or in the bucket', () {
    final c = _seeded();
    expect(c.preCollectionItems.map((i) => i.id).toSet(), {'P1', 'P4'});
    expect(c.preCollectionAccounts.map((a) => a.name).toSet(),
        {'Amka Trading', 'Ace Diagnostics Corp.'});
    expect(c.getPreCollectionInvoicesByAccount(_amka.id).map((i) => i.id),
        ['P1']);
  });

  test('follows Filter by Area', () {
    final c = _seeded()..selectedArea.value = 'NCR';
    expect(c.preCollectionItems.map((i) => i.id), ['P1']);
  });

  test('nothing marked Pre-Collection: zero', () {
    final c = Get.put<CollectionActivityController>(_Activity()) as _Activity;
    c.startAggregateTracking();
    c.bucketItems.assignAll(
        [_invoice('X', _amka, outcome: null), _invoice('Y', _ace, outcome: '')]);
    expect(c.preCollectionItems, isEmpty);
  });

  testWidgets('the card opens its accounts', (tester) async {
    _seeded();
    await tester.pumpWidget(GetMaterialApp(
      theme: BCollectionTheme.light,
      home: CategoryDetailScreen(
          title: CollectionStatusColors.statusPreCollection,
          color: BCollectionColors.primary),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Amka Trading'), findsOneWidget);
    expect(find.text('Ace Diagnostics Corp.'), findsOneWidget);
    expect(find.text('No accounts found for this category.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
