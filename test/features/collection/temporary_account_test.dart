import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/temporary_account.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/advanced_payment_form.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/category_detail_screen.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// A temporary account for an advanced payment (update checklist item 16):
/// an account the collector names when it is not in the client registry
/// yet. The advance cannot be applied to an invoice until the collector
/// links it to the real account, which moves it there (LINK_ADVANCE).

ClientModel _client(String code, String name) => ClientModel(
    id: code, code: code, name: name, address: '', contact: '', emailAddress: '');

final _real = _client('VIS-052', 'Bohol Diagnostic Center Inc.');

class _Repo extends CollectionRepository {
  final links = <({String ref, String clientId, String name})>[];

  @override
  String get collectorCode => 'JCA';

  @override
  Future<bool> linkAdvance({
    required String externalRef,
    required String clientId,
    required String clientName,
  }) async {
    links.add((ref: externalRef, clientId: clientId, name: clientName));
    return true;
  }
}

class _Activity extends CollectionActivityController {
  _Activity(this._repo);
  final _Repo _repo;
  final saved = <({String clientId, String? clientName, double amount})>[];
  final applied = <String>[];

  @override
  // ignore: must_call_super
  void onInit() => repository = _repo;

  @override
  Future<Result<List<ClientModel>>> searchClientRegistry(String term) async =>
      Result.success([_real]);

  @override
  List<ClientModel> searchKnownAccounts(String term) => const [];

  @override
  Future<void> saveAdvancedPayment({
    required String clientId,
    required double amount,
    required String remarks,
    String? clientName,
  }) async =>
      saved.add((clientId: clientId, clientName: clientName, amount: amount));
}

Map<String, dynamic> _advance(String id, String clientId, String name) => {
      'id': id,
      'clientId': clientId,
      'clientName': name,
      'amount': 5000.0,
      'remarks': '',
      'date': '2026-10-20T09:00:00.000',
      'collectorName': 'Jay',
    };

void main() {
  tearDown(Get.reset);

  group('BTemporaryAccount', () {
    test('a code the server knows as temporary, the name as given', () {
      final c = BTemporaryAccount.create(
          name: '  Bohol   Diagnostic Center ',
          collectorCode: 'jca',
          now: DateTime(2026, 10, 20, 9, 5, 7));
      expect(c.id, 'TMP-JCA-20261020090507');
      expect(c.code, c.id);
      expect(c.name, 'Bohol Diagnostic Center');
      expect(BTemporaryAccount.isTemporary(c.id), isTrue);
      expect(BTemporaryAccount.isTemporary('VIS-052'), isFalse);
      expect(BTemporaryAccount.isTemporary(null), isFalse);
    });
  });

  group('the controller', () {
    late _Repo repo;
    late _Activity c;

    setUp(() {
      repo = _Repo();
      c = Get.put<CollectionActivityController>(_Activity(repo)) as _Activity;
      c.startAggregateTracking();
    });

    test('a new temporary account is under the collector', () {
      final t = c.newTemporaryAccount('Bohol Diagnostic Center');
      expect(t.id, startsWith('TMP-JCA-'));
      expect(t.name, 'Bohol Diagnostic Center');
    });

    test('linking moves the advance to the real account', () async {
      c.unassignedAdvancedPayments
          .assignAll([_advance('AP-T1', 'TMP-JCA-1', 'Bohol Diagnostic')]);
      expect(CollectionActivityController.isOnTemporaryAccount(
              c.unassignedAdvancedPayments.single),
          isTrue);

      expect(await c.linkAdvance('AP-T1', _real), isTrue);
      expect(repo.links.single,
          (ref: 'AP-T1', clientId: 'VIS-052', name: _real.name));
      final p = c.unassignedAdvancedPayments.single;
      expect(p['clientId'], 'VIS-052');
      expect(p['clientName'], _real.name);
      expect(CollectionActivityController.isOnTemporaryAccount(p), isFalse);
    });

    test('never to another temporary account', () async {
      c.unassignedAdvancedPayments
          .assignAll([_advance('AP-T1', 'TMP-JCA-1', 'X')]);
      expect(await c.linkAdvance('AP-T1', _client('TMP-JCA-2', 'Y')), isFalse);
      expect(repo.links, isEmpty);
    });

    test('it cannot be applied before it is linked', () async {
      c.unassignedAdvancedPayments
          .assignAll([_advance('AP-T1', 'TMP-JCA-1', 'X')]);
      final left = await c.assignInvoiceToPayment(
        paymentId: 'AP-T1',
        invoiceNumber: 'SI-1',
        amountDue: 1000,
        dueDate: '2026-10-30',
        collectionDate: DateTime(2026, 10, 20),
      );
      expect(left, 5000, reason: 'nothing applied');
      expect(c.errorMessage.value, contains('Link this advance'));
      expect(c.unassignedAdvancedPayments.single['amount'], 5000.0);
    });

    test('a temporary account shows under every area', () {
      c.unassignedAdvancedPayments.assignAll([
        _advance('AP-T1', 'TMP-JCA-1', 'X'),
        _advance('AP-2', 'NLN-9', 'Y'),
      ]);
      c.selectedArea.value = 'VIS';
      expect(c.filteredUnassignedAdvancedPayments.map((p) => p['id']),
          ['AP-T1']);
    });
  });

  group('the form', () {
    testWidgets('a temporary account is named and saved with the advance',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c =
          Get.put<CollectionActivityController>(_Activity(_Repo())) as _Activity;
      await tester.pumpWidget(GetMaterialApp(
          theme: BCollectionTheme.light,
          home: const AdvancedPaymentFormScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('advance-temporary')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('advance-temporary-name')),
          'Bohol Diagnostic Center');
      await tester.tap(find.byKey(const ValueKey('advance-temporary-use')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('advance-temporary-note')),
          findsOneWidget);
      expect(find.text('Bohol Diagnostic Center'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '5000');
      await tester.tap(find.text('Record advanced payment'));
      await tester.pumpAndSettle();

      final s = c.saved.single;
      expect(s.clientId, startsWith('TMP-JCA-'));
      expect(s.clientName, 'Bohol Diagnostic Center');
      expect(s.amount, 5000);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('a blank name uses nothing', (tester) async {
      Get.put<CollectionActivityController>(_Activity(_Repo()));
      await tester.pumpWidget(GetMaterialApp(
          theme: BCollectionTheme.light,
          home: const AdvancedPaymentFormScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('advance-temporary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('advance-temporary-use')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('advance-temporary-note')), findsNothing);
    });
  });

  group('the Advanced Payment list', () {
    testWidgets('a temporary account offers Link, not Apply, and links',
        (tester) async {
      final repo = _Repo();
      final c = Get.put<CollectionActivityController>(_Activity(repo))
          as _Activity;
      c.unassignedAdvancedPayments.assignAll([
        _advance('AP-T1', 'TMP-JCA-1', 'Bohol Diagnostic Center'),
        _advance('AP-2', 'NLN-9', 'Antipolo Doctors'),
      ]);
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 1400)),
          child: CategoryDetailScreen(
              title: 'Advanced Payment', color: BCollectionColors.warning),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Temporary account · link to apply'), findsOneWidget);
      expect(find.text('Link to account'), findsOneWidget);
      expect(find.text('Apply to invoice'), findsOneWidget,
          reason: 'the other advance is on a real account');

      await tester.tap(find.byKey(const ValueKey('advance-action-AP-T1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_real.name).last);
      await tester.pumpAndSettle();

      expect(repo.links.single.clientId, 'VIS-052');
      expect(find.text('Link to account'), findsNothing);
      expect(find.text('Apply to invoice'), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
