import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_alias_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/client/client_alias_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_document_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/standard_delivery_form_state.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/client_match_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/delivery_document_scan_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scanned_client_header.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/i_delivery_document_scan_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeService implements IDeliveryDocumentScanService {
  _FakeService(this.result);

  final Result<DeliveryDocumentScanResult> result;
  var cleared = 0;

  @override
  Future<Result<DeliveryDocumentScanResult>> scan(File image) async => result;

  @override
  void clearCache() => cleared++;

  @override
  List<OcrLine> get lastLines => const [];
}

ClientModel _client(String id, String name, String address) => ClientModel(
    id: id, name: name, address: address, contact: '', emailAddress: '');

final _scan = DeliveryDocumentScanResult(
  header: const ScannedClientHeader(
    label: 'Business Partner',
    prefix: 'DLR-190',
    name: 'Galinato Clinic and Hospital',
    address: 'Villamor, Esperanza Sultran Kudarat PHILIPPINES',
  ),
  match: ClientMatchResult.none,
  references: const ['ITRNo.:810003448', 'SIS#:00611'],
  items: ItemTableReading(headerFound: true, items: [
    InventoryItemModel(
        itemCode: 'RXH60169',
        description: 'Optic Bench / WBC Chamber',
        qty: 1,
        unit: 'PIECE'),
  ]),
);

StandardDeliveryController _form() =>
    StandardDeliveryController()..formState = StandardDeliveryFormState();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ClientAliasDao dao;
  late DeliveryDocumentScanController scan;
  late _FakeService service;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, v) async {
      await db.execute('CREATE TABLE ACCMST_ (ACCMID TEXT, ACCMNM TEXT)');
      await ensureOneScanTables(db);
    });
    dao = ClientAliasDao(db);
    service = _FakeService(Result.success(_scan));
    scan = DeliveryDocumentScanController(
      service: service,
      aliases: ClientAliasRepository(dao: () async => dao),
    );
    await scan.scanFile(File('photo'));
  });

  tearDown(() async => db.close());

  test('a scan never selects a client; Apply waits for a tap or Skip', () {
    expect(scan.confirmedClient.value, isNull);
    expect(scan.canApply, isFalse);
    scan.chooseSkipClient();
    expect(scan.canApply, isTrue);
  });

  test('confirming a client with no saved address uses the scanned one',
      () async {
    await scan.confirmClient(_client('C-1', 'GALINATO CLINIC & HOSPITAL', 'N/A'));
    expect(scan.confirmedClient.value!.address,
        'Villamor, Esperanza Sultran Kudarat PHILIPPINES');
    expect(scan.addressFromScan.value, isTrue);
    expect(await dao.findByAlias('GALINATO CLINIC AND HOSPITAL'), 'C-1',
        reason: 'the scanned name is remembered');
  });

  test('a saved address wins over the scanned one', () async {
    await scan.confirmClient(_client('C-1', 'GALINATO', 'Isulan, Sultan Kudarat'));
    expect(scan.confirmedClient.value!.address, 'Isulan, Sultan Kudarat');
    expect(scan.addressFromScan.value, isFalse);
  });

  test('apply fills client, ticked references and items', () async {
    final form = _form();
    form.formState.documentReferenceControllers
        .add(TextEditingController(text: 'sis#:00611'));
    await scan.confirmClient(_client('C-1', 'GALINATO', ''));
    scan.toggleReference('ITRNo.:810003448'); // untick
    scan.toggleReference('ITRNo.:810003448'); // tick again

    final applied = scan.applyToForm(form);

    expect(applied.clientSet, isTrue);
    expect(form.formState.clientInformation.value!.id, 'C-1');
    expect(form.formState.scannedFallbackAddress.value,
        (clientId: 'C-1', address: 'Villamor, Esperanza Sultran Kudarat PHILIPPINES'));
    expect(form.formState.documentReferenceControllers.map((c) => c.text),
        ['sis#:00611', 'ITRNo.:810003448'],
        reason: 'the SIS already there is not added twice');
    expect(applied.referencesAdded, 1);
    expect(form.formState.scannedInventoryItems.single.itemCode, 'RXH60169');
  });

  test('an unticked reference is left out; skip leaves the client alone', () {
    final form = _form();
    form.updateRequestClientInformation(_client('C-9', 'OTHER', 'x'));
    scan.toggleReference('SIS#:00611');
    scan.chooseSkipClient();

    final applied = scan.applyToForm(form);

    expect(applied.clientSet, isFalse);
    expect(form.formState.clientInformation.value!.id, 'C-9');
    expect(form.formState.documentReferenceControllers.map((c) => c.text),
        ['ITRNo.:810003448']);
  });

  test('empty reference fields are filled before new ones are added', () {
    final form = _form();
    form.formState.documentReferenceControllers.add(TextEditingController());
    expect(form.appendDocumentReferences(['A', 'B', 'a']), 2);
    expect(form.formState.documentReferenceControllers.map((c) => c.text),
        ['A', 'B']);
  });

  test('a different client already on the form needs a confirm', () async {
    final form = _form();
    form.updateRequestClientInformation(_client('C-9', 'OTHER', 'x'));
    await scan.confirmClient(_client('C-1', 'GALINATO', 'y'));
    expect(scan.replacesClientOn(form), isTrue);
    form.updateRequestClientInformation(_client('C-1', 'GALINATO', 'y'));
    expect(scan.replacesClientOn(form), isFalse);
  });

  test('a failed scan sets the error', () async {
    final failing = DeliveryDocumentScanController(
      service: _FakeService(Result.failure('Could not read the document')),
      aliases: ClientAliasRepository(dao: () async => dao),
    );
    expect(await failing.scanFile(File('x')), isFalse);
    expect(failing.error.value, 'Could not read the document');
  });

  test('warns when the document is not one for Standard Delivery', () async {
    DeliveryDocumentScanController forType(DeliveryDocumentType type) =>
        DeliveryDocumentScanController(
          service: _FakeService(Result.success(DeliveryDocumentScanResult(
            header: _scan.header,
            match: _scan.match,
            references: _scan.references,
            items: _scan.items,
            documentType: type,
          ))),
          aliases: ClientAliasRepository(dao: () async => dao),
        );

    final it = forType(DeliveryDocumentType.inventoryTransfer);
    await it.scanFile(File('x'));
    expect(it.documentWarning, contains('not Standard Delivery'));

    final si = forType(DeliveryDocumentType.salesInvoice);
    await si.scanFile(File('x'));
    expect(si.documentWarning, isNull);

    expect(scan.documentWarning, isNull, reason: 'unknown title: no warning');
  });

  group('scan first', () {
    DeliveryDocumentScanController forType(DeliveryDocumentType type) =>
        DeliveryDocumentScanController(
          service: _FakeService(Result.success(DeliveryDocumentScanResult(
            header: _scan.header,
            match: _scan.match,
            references: _scan.references,
            items: _scan.items,
            documentType: type,
          ))),
          aliases: ClientAliasRepository(dao: () async => dao),
        );

    test('several forms: the user picks one before Apply', () async {
      final s = forType(DeliveryDocumentType.salesInvoice);
      await s.scanFile(File('x'), fixedTarget: null, role: 'Request');
      expect(s.choosesTarget.value, isTrue);
      expect(s.targetChoices, [
        DeliveryRequestForm.standardDelivery,
        DeliveryRequestForm.airSeaLand,
      ]);
      expect(s.target.value, isNull);
      s.chooseSkipClient();
      expect(s.canApply, isFalse, reason: 'no request chosen yet');
      s.chooseTarget(DeliveryRequestForm.airSeaLand);
      expect(s.canApply, isTrue);
      expect(s.documentWarning, isNull);
    });

    test('one form: it is chosen already', () async {
      final s = forType(DeliveryDocumentType.returnPullOutSlip);
      await s.scanFile(File('x'), fixedTarget: null, role: 'Request');
      expect(s.target.value, DeliveryRequestForm.pullOut);
    });

    test('Air/Sea and Pull Out both take the items', () async {
      final airSea = forType(DeliveryDocumentType.salesInvoice);
      await airSea.scanFile(File('x'), fixedTarget: null, role: 'Request');
      airSea
        ..chooseTarget(DeliveryRequestForm.airSeaLand)
        ..chooseSkipClient();
      final form = _form();
      final applied = airSea.applyToForm(form);
      expect(applied.itemsAdded, 1);
      expect(applied.itemsSkipped, isFalse);
      expect(applied.target, DeliveryRequestForm.airSeaLand);
      expect(form.formState.scannedInventoryItems.single.itemCode, 'RXH60169');
      expect(applied.referencesAdded, 2, reason: 'references still go in');

      final pullOut = forType(DeliveryDocumentType.returnPullOutSlip);
      await pullOut.scanFile(File('x'), fixedTarget: null, role: 'Request');
      pullOut.chooseSkipClient();
      expect(pullOut.applyToForm(_form()).itemsAdded, 1);
    });

    test('an open form fixes the target and warns on a mismatch', () async {
      final s = forType(DeliveryDocumentType.inventoryTransfer);
      await s.scanFile(File('x'),
          fixedTarget: DeliveryRequestForm.hotlineDirect);
      expect(s.choosesTarget.value, isFalse);
      expect(s.documentWarning, contains('not Hotline Direct'));
    });
  });

  test('closing frees the client index', () {
    scan.onClose();
    expect(service.cleared, 1);
  });

  group('page source', () {
    DeliveryDocumentScanController withScanner(
      Future<List<File>?> Function() documentScan,
      List<ImageSource> opened,
    ) =>
        DeliveryDocumentScanController(
          service: service,
          aliases: ClientAliasRepository(dao: () async => dao),
          documentScan: documentScan,
          pickImage: (source) async {
            opened.add(source);
            return File('plain-${source.name}');
          },
        );

    test('the flattened page from the document scanner is read', () async {
      final opened = <ImageSource>[];
      final c = withScanner(() async => [File('flat.jpg')], opened);
      expect((await c.pickPage(DocumentScanSource.scanner))!.path, 'flat.jpg');
      expect(opened, isEmpty);
    });

    test('where the scanner cannot run, the plain camera opens', () async {
      final opened = <ImageSource>[];
      final c = withScanner(() async => null, opened);
      expect((await c.pickPage(DocumentScanSource.scanner))!.path, 'plain-camera');
      expect(opened, [ImageSource.camera]);
    });

    test('cancelling the scanner reads nothing and opens nothing', () async {
      final opened = <ImageSource>[];
      final c = withScanner(() async => const [], opened);
      expect(await c.pickPage(DocumentScanSource.scanner), isNull);
      expect(opened, isEmpty);
      expect(c.error.value, isNull);
    });

    test('camera and gallery are read as taken', () async {
      final opened = <ImageSource>[];
      final c = withScanner(() async => fail('no scanner'), opened);
      await c.pickPage(DocumentScanSource.camera);
      await c.pickPage(DocumentScanSource.gallery);
      expect(opened, [ImageSource.camera, ImageSource.gallery]);
    });
  });
}
