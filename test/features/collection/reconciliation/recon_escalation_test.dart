import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_case_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Escalating a case texts the Head (Settings > My Head), and only the Head.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late Directory photos;
  late List<(String, String)> texts;
  late ReconciliationController controller;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
    photos = await Directory.systemTemp.createTemp('recon_escalate_');
    texts = [];
    var clock = DateTime.parse('2026-09-28T10:00:00+08:00');
    final repo = ReconciliationRepository(
      caseDao: () async => ReconCaseDao(db),
      attachmentDao: () async => ReconAttachmentDao(db),
      queue: (_, __, ___) async {},
      collectorCode: () => 'JCA',
      collectorName: () => 'Jay',
      now: () => clock = clock.add(const Duration(seconds: 1)),
      attachmentDirectory: () async => photos,
    );
    Get.put<CollectionSmsService>(CollectionSmsService(
      head: () async =>
          const HeadContact(key: 'MDD', name: 'Maria', phone: '0917 000 0001'),
      contacts: () async => ['0918 000 0002'],
      permission: () async => true,
      networkIssue: () async => null,
      smsAvailable: () => true,
      send: (to, message, onStatus) async {
        texts.add((to, message));
        onStatus(SendStatus.SENT);
      },
      report: (_, __, ___) {},
      openProgress: (_) {},
      closeProgress: () {},
      showSent: () async {},
      betweenRecipients: Duration.zero,
      initials: () => 'JCA',
    ));
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

  Future<String> open() async => (await controller.openCase(
              clientCode: 'RAD-022',
              clientName:
                  'Allied Care Experts (ACE) Medical Center - Bohol, Inc.',
              invoices: const [
            ReconCaseInvoice(invoiceNo: '700004812', amount: 276995),
          ]))
          .value
          .caseId;

  test('an escalation texts the Head alone, with the open amount', () async {
    final caseId = await open();
    final r = await controller.logActivity(
        caseId: caseId,
        type: ReconActivityType.caseEscalated,
        remarks: 'No proof after three follow-ups');
    expect(r.isSuccess, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(texts.single.$1, '0917 000 0001',
        reason: 'the Head, not the Collection contacts');
    expect(
        texts.single.$2,
        'Reconciliation escalated: Allied Care Experts (ACE) Medical Center - '
        'Bohol, Inc. 1 open invoice, PHP 276,995.00. Reason: No proof after '
        'three follow-ups. - JCA');
    expect(controller.caseById(caseId)!.evaluation.status,
        ReconCaseStatus.escalated);
  });

  test('other steps send nothing', () async {
    final caseId = await open();
    await controller.logActivity(
        caseId: caseId, type: ReconActivityType.soaSent);
    await controller.logActivity(
        caseId: caseId, type: ReconActivityType.caseNotCompleted);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(texts, isEmpty);
  });
}
