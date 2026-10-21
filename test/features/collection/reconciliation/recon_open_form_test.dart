import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_case_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The Open Reconciliation Case form offers only what a new case may take:
/// an account already in an open case is sent to that case, and invoices
/// already marked for reconciliation are not offered again.

final _ace = ClientModel(
    id: 'RAD-022',
    code: 'RAD-022',
    name: 'Allied Care Experts (ACE) Medical Center - Bohol, Inc.',
    address: '',
    contact: '',
    emailAddress: '');

CollectionItemModel _invoice(String id, double due, {String status = ''}) =>
    CollectionItemModel(
        id: id, client: _ace, toBeCollected: due, status: status);

void main() {
  group('the invoices offered', () {
    final invoices = [
      _invoice('700004695', 308089.68),
      _invoice('700004812', 526995, status: 'Reconciliation'),
      _invoice('700011771', 165000),
      _invoice('700007561', 0),
    ];

    test('leave out marked, paid-off and open-case invoices', () {
      expect(
          CollectionActivityController.openableForReconciliation(invoices,
              inOpenCase: {'700011771'}).map((i) => i.id),
          ['700004695']);
    });

    test('take back a marked invoice whose case has ended', () {
      expect(
          CollectionActivityController.openableForReconciliation(invoices,
              inEndedCase: {'700004812'}).map((i) => i.id),
          ['700004695', '700004812', '700011771']);
    });
  });

  group('the tracker', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    late Database db;
    late Directory photos;
    late ReconciliationController controller;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
      photos = await Directory.systemTemp.createTemp('recon_open_form_');
      var clock = DateTime.parse('2026-10-20T10:00:00+08:00');
      final repo = ReconciliationRepository(
        caseDao: () async => ReconCaseDao(db),
        attachmentDao: () async => ReconAttachmentDao(db),
        queue: (_, __, ___) async {},
        collectorCode: () => 'JCA',
        collectorName: () => 'Jay',
        now: () => clock = clock.add(const Duration(seconds: 1)),
        attachmentDirectory: () async => photos,
      );
      controller = Get.put(ReconciliationController(
        repository: repo,
        collectorCode: () => 'JCA',
        heldInvoiceIds: () => {},
        isHead: () => false,
        now: () => clock,
      ));
    });

    tearDown(() async {
      Get.reset();
      await db.close();
      if (await photos.exists()) await photos.delete(recursive: true);
    });

    test('knows the account\'s open case and its invoices', () async {
      expect(controller.openCaseOf('RAD-022'), isNull);

      final opened = await controller.openCase(
          clientCode: 'RAD-022',
          clientName: _ace.name,
          invoices: const [
            ReconCaseInvoice(invoiceNo: '700004812', amount: 526995),
          ]);
      expect(opened.isSuccess, isTrue);

      expect(controller.openCaseOf('RAD-022')?.caseId, opened.value.caseId);
      expect(controller.openCaseOf('NLN-1'), isNull);
      expect(controller.openCaseInvoiceIds, {'700004812'});
    });
  });
}
