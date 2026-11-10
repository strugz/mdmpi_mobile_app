import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/collection_repository.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_status_colors.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/routing_documents_form.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/activity_type_modal.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Routing of Documents (update checklist item 7): one account and what was
/// routed, for tracking only. It uploads as its own account-level operation,
/// texts the Head like a CWT Pick-up, and never counts as money collected.

ClientModel _client(String code, String name) => ClientModel(
    id: code, code: code, name: name, address: '', contact: '', emailAddress: '');

final _registry = [
  _client('C-100', 'Antipolo Doctors Hospital'),
  _client('C-300', 'Accuteqs Diagnostics Corp.'),
];

class _Activity extends CollectionActivityController {
  final saved = <({String type, String? clientId, String name, String remarks})>[];

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<Result<List<ClientModel>>> searchClientRegistry(String term) async {
    final q = term.trim().toLowerCase();
    return Result.success([
      for (final c in _registry)
        if (q.isEmpty || c.name.toLowerCase().contains(q)) c,
    ]);
  }

  @override
  List<ClientModel> searchKnownAccounts(String term) => const [];

  @override
  Future<void> saveGlobalActivity({
    required String type,
    required String accountName,
    required String remarks,
    double totalCollected = 0,
    String? bankName,
    String? checkNumber,
    String? clientId,
    List<String> documentIds = const [],
  }) async =>
      saved.add(
          (type: type, clientId: clientId, name: accountName, remarks: remarks));
}

void main() {
  tearDown(Get.reset);

  Future<_Activity> pump(WidgetTester tester) async {
    final activity = _Activity();
    Get.put<CollectionActivityController>(activity);
    await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: const RoutingDocumentsFormScreen()));
    await tester.pumpAndSettle();
    return activity;
  }

  Future<void> pick(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const ValueKey('routing-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  group('the form', () {
    testWidgets('asks for an account and remarks', (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('routing-account')), findsOneWidget);
      expect(find.byKey(const ValueKey('routing-remarks')), findsOneWidget);
      expect(find.text('Record Routing of Documents'), findsOneWidget);
    });

    testWidgets('remarks are required, spaces included', (tester) async {
      final activity = await pump(tester);
      await pick(tester, 'Antipolo Doctors Hospital');
      await tester.enterText(
          find.byKey(const ValueKey('routing-remarks')), '   ');
      await tester.tap(find.byKey(const ValueKey('routing-save')));
      await tester.pumpAndSettle();

      expect(find.text('Remarks are required'), findsOneWidget);
      expect(activity.saved, isEmpty);
    });

    testWidgets('no account: nothing is saved', (tester) async {
      final activity = await pump(tester);
      await tester.enterText(
          find.byKey(const ValueKey('routing-remarks')), 'SOA delivered');
      await tester.tap(find.byKey(const ValueKey('routing-save')));
      await tester.pump();

      expect(activity.saved, isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('saves the account and the trimmed remarks', (tester) async {
      final activity = await pump(tester);
      await pick(tester, 'Accuteqs Diagnostics Corp.');
      await tester.enterText(find.byKey(const ValueKey('routing-remarks')),
          '  SOA and 2307 delivered to accounting  ');
      await tester.tap(find.byKey(const ValueKey('routing-save')));
      await tester.pumpAndSettle();

      final r = activity.saved.single;
      expect(r.type, CollectionStatusColors.statusRoutingDocuments);
      expect(r.clientId, 'C-300');
      expect(r.name, 'Accuteqs Diagnostics Corp.');
      expect(r.remarks, 'SOA and 2307 delivered to accounting');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  test('it is on the Add field engagement sheet, opening its own form', () {
    expect(
        ActivityTypeModal.types
            .map((t) => t.title)
            .contains(CollectionStatusColors.statusRoutingDocuments),
        isTrue);
    expect(
        ActivityTypeModal.routeFor(
            CollectionStatusColors.statusRoutingDocuments),
        '/collection/engagement/routing-documents');
  });

  test('it uploads as its own account-level operation', () {
    expect(
        CollectionRepository.operationForActivity('Routing of Documents'),
        'ROUTING_DOCUMENTS');
    expect(CollectionRepository.operationForActivity('CWT Pick-up'),
        'CWT_PICKUP',
        reason: 'the others are unchanged');
  });

  test('it is an activity, never money collected', () {
    expect(
        CollectionOutcome.countsAsCollected(
            CollectionStatusColors.statusRoutingDocuments,
            kind: 'OFFICE'),
        isFalse);
  });

  test('the SMS names the account and what was routed', () {
    expect(
      CollectionSmsService.documentsRouted(
          clientName: 'Antipolo Doctors Hospital',
          remarks: 'SOA and 2307 delivered'),
      'Routed documents: Antipolo Doctors Hospital\n'
      'Note: SOA and 2307 delivered',
    );
    expect(
        CollectionSmsService.documentsRouted(clientName: 'X', remarks: ' '),
        'Routed documents: X');
    expect(
        RegExp(r'^[\x20-\x7E\n]*$').hasMatch(CollectionSmsService.documentsRouted(
            clientName: 'Accuteqs Diagnostics Corp.', remarks: 'r')),
        isTrue,
        reason: 'plain SMS text');
  });
}
