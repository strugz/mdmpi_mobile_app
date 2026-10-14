import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/bindings/app/general_bindings.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_attachment_dao.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/recon_case_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/reconciliation_repository.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/reconciliation_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_case_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The calendar's "Open reconciliation case" form is often the first screen
/// to use the Tracker, and it replaces itself with the case (Get.offNamed).
/// GetX deletes what a disposed route created, so the Tracker must outlive
/// that route: otherwise the case screen keeps listening to the deleted
/// controller, and a step logged there never shows on its stage track.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  tearDown(Get.reset);

  testWidgets('a step logged after the form hands over shows on the stage',
      (tester) async {
    late Database db;
    await tester.runAsync(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, _) async => ensureCollectionTables(db));
    });
    addTearDown(() => tester.runAsync(db.close));

    // As GeneralBindings registers it; nothing created yet.
    registerTracker(() => ReconciliationRepository(
          caseDao: () async => ReconCaseDao(db),
          attachmentDao: () async => ReconAttachmentDao(db),
          queue: (_, __, ___) async {},
          collectorCode: () => 'JCA',
          collectorName: () => 'Jay',
        ));

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      theme: BCollectionTheme.light,
      initialRoute: '/home',
      getPages: [
        GetPage(
            name: '/home',
            page: () => Scaffold(
                body: TextButton(
                    onPressed: () => Get.toNamed('/form'),
                    child: const Text('calendar')))),
        // Stands in for ReconciliationFormScreen: the Tracker is first used
        // here, then the form replaces itself with the case.
        GetPage(
            name: '/form',
            page: () => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      final tracker = ReconciliationController.instance;
                      final opened = await tracker.openCase(
                        clientCode: 'NCR-387',
                        clientName: 'Accuteqs Diagnostics Corp.',
                        invoices: const [
                          ReconCaseInvoice(invoiceNo: '240006226', amount: 85740)
                        ],
                      );
                      Get.offNamed('/case', arguments: opened.value.caseId);
                    },
                    child: const Text('open case')))),
        GetPage(
            name: '/case',
            page: () => ReconCaseScreen(caseId: Get.arguments as String)),
      ],
    ));
    await tester.tap(find.text('calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open case'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('recon-stage-track')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recon-stage-soa')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('recon-save')));
    await tester.tap(find.byKey(const ValueKey('recon-save')));
    await _settle(tester);

    final soa = tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(const ValueKey('recon-stage-soa')),
            matching: find.byType(Text)))
        .map((t) => t.data)
        .toList();
    expect(soa, isNot(contains('next')),
        reason: 'the SOA is logged; its node shows the date');
    expect(find.text('Timeline (1)'), findsOneWidget);
  });
}

void registerTracker(ReconciliationRepository Function() repository) =>
    GeneralBindings.registerReconciliationTracker(
      repository: repository,
      controller: () => ReconciliationController(
          repository: Get.find<ReconciliationRepository>(),
          collectorCode: () => 'JCA',
          heldInvoiceIds: () => {}),
    );

/// Lets the real SQLite work finish between frames.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
