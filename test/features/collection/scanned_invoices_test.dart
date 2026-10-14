import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/voucher_reread_dao.dart';
import 'package:mdmpi_mobile_app/data/repositories/collection/voucher_invoice_repository.dart';
import 'package:mdmpi_mobile_app/data/services/outbox/voucher_reread_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_si_matcher.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/voucher_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/activity_account_invoices_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/scanned_invoices_screen.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/voucher_file_picker.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Scanned Invoices: a client's voucher read by the AI (SI / Invoice / Sales
/// Invoice numbers), checked against the account, corrected, and carted.

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
        id: id, client: _client, toBeCollected: due, poNumber: po);

_Stub _seeded() {
  final c = Get.put<CollectionActivityController>(_Stub()) as _Stub;
  c.startAggregateTracking();
  c.masterAccountList.assignAll([_client]);
  c.activityItems.assignAll([
    _inv('700013390', 1000, po: '4500012345'),
    _inv('700013391', 2000),
    _inv('97339', 500),
  ]);
  c.bucketItems.assign(_inv('700055555', 300));
  return c;
}

/// What the fake AI returns, per call; null means the AI failed.
class _Ai {
  final pages = <List<dynamic>?>[];
  final prompts = <String>[];
  String offline = '';

  VoucherInvoiceRepository repository() => VoucherInvoiceRepository(
        readWithAi: (file, {required prompt}) async {
          prompts.add(prompt);
          final page = pages.removeAt(0);
          return page == null
              ? Result.failure('AI service error: 503')
              : Result.success(page);
        },
        readOffline: (_) async => _lines(offline),
        envPrompt: () => null,
      );
}

/// [text] as the phone's reader gives it: one line per row, stacked.
List<OcrLine> _lines(String text) => [
      for (final (i, line) in text.split('\n').indexed)
        OcrLine(line, Rect.fromLTWH(0, i * 30.0, 320, 24)),
    ];

final _photo = File('${Directory.systemTemp.path}/voucher_test.jpg');
final _pdf = File('${Directory.systemTemp.path}/voucher_test.pdf');

void main() {
  tearDown(Get.reset);

  group('reading the AI answer', () {
    test('lines: labels, number or text amounts, duplicates and blanks', () {
      final lines = VoucherInvoiceLine.listFrom([
        {'Invoice No.': '700013390', 'Label': 'SI', 'Amount': 21048.87},
        {'Invoice No.': '0097339', 'Label': 'Sales Invoice', 'Amount': '1,500.00'},
        {'Invoice No.': '700013390', 'Label': 'SI', 'Amount': ''},
        {'Invoice No.': '', 'Label': 'SI'},
        'garbage',
      ]);
      expect(lines.map((l) => l.invoiceNo), ['700013390', '0097339']);
      expect(lines[0].amount, 21048.87);
      expect(lines[1].amount, 1500);
      expect(lines[1].label, 'Sales Invoice');
    });

    test('each AI number becomes a tile with its standing', () {
      const classify = ScannedInvoiceClassifier(
          knownIds: ['700013390', '97339'], elsewhereIds: ['700055555']);
      ScannedInvoiceStatus s(String n) =>
          classify.line(VoucherInvoiceLine(invoiceNo: n)).status;
      expect(s('0097339'), ScannedInvoiceStatus.matched);
      expect(classify.line(const VoucherInvoiceLine(invoiceNo: 'SI-0097339'))
          .invoiceId, '97339');
      expect(s('700055555'), ScannedInvoiceStatus.elsewhere);
      expect(s('123'), ScannedInvoiceStatus.notFound,
          reason: 'labelled an invoice, so shown even when short');
    });
  });

  group('repository', () {
    setUp(() async => _photo.writeAsBytes([1, 2, 3]));

    test('the AI is asked with the voucher prompt', () async {
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': '700013390', 'Label': 'SI', 'Amount': ''}
        ]);
      final r = await ai.repository().read(_photo);
      expect(r.value.isOffline, isFalse);
      expect(r.value.lines.single.invoiceNo, '700013390');
      expect(ai.prompts.single, VoucherInvoiceRepository.defaultVoucherPrompt);
      expect(ai.prompts.single, contains('Sales Invoice'));
    });

    test('AI down: the phone reads the photo itself', () async {
      final ai = _Ai()
        ..pages.add(null)
        ..offline = 'SI 700013390';
      final r = await ai.repository().read(_photo);
      expect(r.value.isOffline, isTrue);
      expect(r.value.offlineText, 'SI 700013390');
      expect(r.value.aiError, contains('503'));
    });

    test('Scan with camera: read on the phone, the AI never asked', () async {
      final ai = _Ai()..offline = 'SI 700013390';
      final r = await ai.repository().read(_photo, useAi: false);
      expect(ai.prompts, isEmpty);
      expect(r.value.isOffline, isTrue);
      expect(r.value.aiError, isNull);
      await _pdf.writeAsBytes([1]);
      expect((await ai.repository().read(_pdf, useAi: false)).error,
          contains('use Scan with AI'));
    });

    test('the account list passes the choice through', () async {
      _seeded();
      final ai = _Ai()..offline = 'SI 700013391';
      final c = VoucherScanController(repository: ai.repository())
        ..openFor('1');
      final summary = await c.scanAndSelect([_photo], useAi: false);
      expect(ai.prompts, isEmpty);
      expect(summary!.selectedIds, ['700013391']);
      expect(summary.offline, isTrue);
    });

    test('AI down and a PDF: no fallback, a clear reason', () async {
      await _pdf.writeAsBytes([1]);
      final r = await (_Ai()..pages.add(null)).repository().read(_pdf);
      expect(r.isFailure, isTrue);
      expect(r.error, contains('PDF needs a connection'));
    });

    test('an AI_VOUCHER_PROMPT override is used', () async {
      final prompts = <String>[];
      final repo = VoucherInvoiceRepository(
        readWithAi: (f, {required prompt}) async {
          prompts.add(prompt);
          return Result.success(const []);
        },
        readOffline: (_) async => const [],
        envPrompt: () => 'custom prompt',
      );
      await repo.read(_photo);
      expect(prompts.single, 'custom prompt');
    });
  });

  group('controller', () {
    setUp(() async => _photo.writeAsBytes([1, 2, 3]));

    VoucherScanController ctl(_Ai ai) => VoucherScanController(
        repository: ai.repository(),
        activity: () => CollectionActivityController.instance)
      ..openFor('1');

    test('pages add up, numbers are not listed twice, P.O.s are skipped',
        () async {
      _seeded();
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': 'SI-700013390', 'Label': 'SI', 'Amount': 1000},
          {'Invoice No.': '700099999', 'Label': 'Invoice', 'Amount': ''},
        ])
        ..pages.add([
          {'Invoice No.': '700013390', 'Label': 'SI', 'Amount': ''},
          {'Invoice No.': '700055555', 'Label': 'SI', 'Amount': ''},
        ]);
      final c = ctl(ai);
      await c.analyze(_photo);
      await c.analyze(_photo);
      expect(c.tiles.map((t) => (t.read, t.status)), [
        ('SI-700013390', ScannedInvoiceStatus.matched),
        ('700099999', ScannedInvoiceStatus.notFound),
        ('700055555', ScannedInvoiceStatus.elsewhere),
      ]);
      expect(c.addableIds, ['700013390']);
    });

    test('a corrected number is matched again', () async {
      _seeded();
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': '70001339l', 'Label': 'SI', 'Amount': 2000},
          {'Invoice No.': '9733', 'Label': 'SI', 'Amount': 500},
        ]);
      final c = ctl(ai);
      await c.analyze(_photo);
      expect(c.tiles[1].status, ScannedInvoiceStatus.notFound);
      c.edit(1, '97339');
      expect(c.tiles[1].status, ScannedInvoiceStatus.matched);
      expect(c.tiles[1].amount, 500, reason: 'the printed amount stays');
      expect(c.addableIds, ['700013391', '97339']);
    });

    test('offline: only what looks like an invoice, marked offline', () async {
      _seeded();
      final ai = _Ai()
        ..pages.add(null)
        ..offline = 'CV 2026-0098 SI 700013391 PO 4500012345 '
            'Total 3,000.00 700088888';
      final c = ctl(ai);
      await c.analyze(_photo);
      expect(c.anyOffline, isTrue);
      expect(c.tiles.map((t) => t.read), ['700013391', '700088888']);
    });

    test('adding to the cart marks them as from the voucher', () async {
      final activity = _seeded();
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': '97339', 'Label': 'SI', 'Amount': ''}
        ]);
      final c = ctl(ai);
      await c.analyze(_photo);
      expect(c.addToCart(), 1);
      expect(activity.selectedActivityInvoiceIds, {'97339'});
      expect(activity.voucherInvoiceIds, {'97339'});
    });

    test('a multi-page scan selects across its pages, one banner', () async {
      final activity = _seeded();
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': '700013390', 'Label': 'SI', 'Amount': ''}
        ])
        ..pages.add(const []) // a page with nothing on it
        ..pages.add([
          {'Invoice No.': '97339', 'Label': 'SI', 'Amount': ''},
          {'Invoice No.': '700099999', 'Label': 'SI', 'Amount': ''},
        ]);
      final c = ctl(ai);
      final summary = await c.scanAndSelect([_photo, _photo, _photo]);
      expect(summary!.selectedIds, ['700013390', '97339']);
      expect(summary.notFound, ['700099999']);
      expect(c.error.value, isNull, reason: 'one empty page is no failure');
      expect(activity.selectedActivityInvoiceIds, {'700013390', '97339'});
    });

    test('a scan where no page names an invoice fails with the reason',
        () async {
      _seeded();
      final c = ctl(_Ai()..pages.add(const []));
      expect(await c.scanAndSelect([_photo]), isNull);
      expect(c.error.value, 'No invoice numbers were found on that page.');
    });

    test('a page read on the phone is queued for an online re-read', () async {
      _seeded();
      final queued = <({String client, File page, List<String> ids})>[];
      final ai = _Ai()
        ..pages.add(null) // AI down: read on the phone
        ..offline = 'SI 700013391'
        ..pages.add([
          {'Invoice No.': '97339', 'Label': 'SI', 'Amount': ''}
        ]);
      final c = VoucherScanController(
        repository: ai.repository(),
        queueReread: ({
          required clientId,
          clientName = '',
          required page,
          required offlineIds,
        }) async =>
            queued.add((client: clientId, page: page, ids: offlineIds)),
      )..openFor('1');
      await c.analyze(_photo);
      expect(queued.single.client, '1');
      expect(queued.single.ids, ['700013391']);

      await c.analyze(_photo); // read by the AI: nothing to re-read
      expect(queued, hasLength(1));
    });

    test('the banner follows the cart even without the cart listener',
        () async {
      final activity = _seeded();
      // Built without onInit (as after a hot reload): no listener on the cart.
      final c = ctl(_Ai()
        ..pages.add([
          {'Invoice No.': '97339', 'Label': 'SI', 'Amount': ''}
        ]));
      await c.scanAndSelect([_photo]);
      expect(c.bannerFor('1'), isNotNull);
      expect(c.bannerFor('2'), isNull, reason: 'another account');

      activity.exitActivitySelectionMode(); // the batch was recorded
      expect(c.bannerFor('1'), isNull);
    });

    test('another account starts a new list', () async {
      _seeded();
      final c = ctl(_Ai()
        ..pages.add([
          {'Invoice No.': '97339', 'Label': 'SI', 'Amount': ''}
        ]));
      await c.analyze(_photo);
      c.openFor('1');
      expect(c.tiles, hasLength(1));
      c.openFor('2');
      expect(c.tiles, isEmpty);
    });
  });

  group('screen', () {
    setUp(() async => _photo.writeAsBytes([1, 2, 3]));

    Future<_Ai> pump(WidgetTester tester, List<List<dynamic>?> pages) async {
      _seeded();
      final ai = _Ai()..pages.addAll(pages);
      Get.put(VoucherScanController(repository: ai.repository()));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: ScannedInvoicesScreen(
          client: _client,
          cameraAvailable: true,
          takePhoto: () async => [_photo],
          attach: () async => [_photo],
        ),
      ));
      await tester.pumpAndSettle();
      return ai;
    }

    testWidgets('capture lists the numbers; Select ticks them and goes back',
        (tester) async {
      await pump(tester, [
        [
          {'Invoice No.': '700013390', 'Label': 'SI', 'Amount': 1000},
          {'Invoice No.': '700099999', 'Label': 'Sales Invoice', 'Amount': ''},
        ]
      ]);
      expect(tester
          .widget<ButtonStyleButton>(
              find.byKey(const ValueKey('scanned-add-to-cart')))
          .enabled, isFalse);

      await tester.tap(find.byKey(const ValueKey('scanner-capture')));
      await tester.pumpAndSettle();
      expect(find.text('Scanned Invoices (2)'), findsOneWidget);
      expect(find.text('700099999'), findsOneWidget);
      expect(find.textContaining('Not found in this account'), findsOneWidget);
      expect(find.text('Select 1 invoice'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('scanned-add-to-cart')));
      await tester.pumpAndSettle();
      expect(CollectionActivityController.instance.selectedActivityInvoiceIds,
          {'700013390'});
    });

    testWidgets('a misread is corrected in place', (tester) async {
      await pump(tester, [
        [
          {'Invoice No.': '9733', 'Label': 'SI', 'Amount': ''}
        ]
      ]);
      await tester.tap(find.byKey(const ValueKey('scanner-attach')));
      await tester.pumpAndSettle();
      expect(find.text('Select 0 invoices'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('scanned-edit-0')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('scanned-edit-field')), '97339');
      await tester.tap(find.byKey(const ValueKey('scanned-edit-save')));
      await tester.pumpAndSettle();
      expect(find.text('Select 1 invoice'), findsOneWidget);
    });

    testWidgets('AI down shows the offline warning', (tester) async {
      final ai = await pump(tester, [null]);
      ai.offline = 'SI 700013391';
      await tester.tap(find.byKey(const ValueKey('scanner-capture')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scanned-offline')), findsOneWidget);
      expect(find.text('Select 1 invoice'), findsOneWidget);
    });

    testWidgets('scanning on the account list ticks the SIs there',
        (tester) async {
      final activity = _seeded();
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': '700013391', 'Label': 'SI', 'Amount': 2000},
          {'Invoice No.': '0097339', 'Label': 'Sales Invoice', 'Amount': ''},
          {'Invoice No.': '700099999', 'Label': 'SI', 'Amount': ''},
        ]);
      Get.put(VoucherScanController(repository: ai.repository()));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: CollectionActivityAccountInvoicesScreen(
            client: _client, pickVoucher: () async => (pages: [_photo], useAi: true)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('voucher-scan')));
      await tester.pumpAndSettle();
      expect(activity.selectedActivityInvoiceIds, {'700013391', '97339'});
      expect(find.byKey(const ValueKey('cart-bar')), findsOneWidget,
          reason: 'still on the list, in cart mode');
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('voucher-scan-banner-text')))
              .data,
          '2 selected from scan · 1 not found: 700099999');

      await tester.tap(find.byKey(const ValueKey('voucher-scan-details')));
      await tester.pumpAndSettle();
      expect(find.byType(ScannedInvoicesScreen), findsOneWidget);
      expect(find.text('Scanned Invoices (3)'), findsOneWidget);
    });

    testWidgets('the scan banner goes once its invoices are recorded',
        (tester) async {
      final activity = _seeded();
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': '700013391', 'Label': 'SI', 'Amount': ''},
          {'Invoice No.': '97339', 'Label': 'SI', 'Amount': ''},
        ]);
      final scan =
          Get.put(VoucherScanController(repository: ai.repository()));
      await tester.pumpWidget(GetMaterialApp(
        home: CollectionActivityAccountInvoicesScreen(
            client: _client,
            pickVoucher: () async => (pages: [_photo], useAi: true)),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('voucher-scan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('voucher-scan-banner')), findsOneWidget);

      // What saving the batch record does: the cart ends.
      activity.exitActivitySelectionMode();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('voucher-scan-banner')), findsNothing);
      expect(scan.lastScan.value, isNull);
      expect(scan.tiles, isEmpty);
    });

    testWidgets('a scan that selected nothing keeps its banner',
        (tester) async {
      _seeded();
      final ai = _Ai()
        ..pages.add([
          {'Invoice No.': '700099999', 'Label': 'SI', 'Amount': ''},
        ]);
      Get.put(VoucherScanController(repository: ai.repository()));
      await tester.pumpWidget(GetMaterialApp(
        home: CollectionActivityAccountInvoicesScreen(
            client: _client,
            pickVoucher: () async => (pages: [_photo], useAi: true)),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('voucher-scan')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('voucher-scan-banner-text')))
              .data,
          '0 selected from scan · 1 not found: 700099999');
    });

    testWidgets('a scan that reads nothing says why on the list',
        (tester) async {
      final activity = _seeded();
      final ai = _Ai()..pages.add(const []);
      Get.put(VoucherScanController(repository: ai.repository()));
      await tester.pumpWidget(GetMaterialApp(
        home: CollectionActivityAccountInvoicesScreen(
            client: _client, pickVoucher: () async => (pages: [_photo], useAi: true)),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('voucher-scan')));
      await tester.pumpAndSettle();
      expect(find.text('Voucher not read'), findsOneWidget);
      expect(activity.selectedActivityInvoiceIds, isEmpty);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('findings of an online re-read can be selected on the list',
        (tester) async {
      final activity = _seeded();
      Get.put(VoucherScanController(repository: _Ai().repository()));
      final reread = Get.put(VoucherRereadService(
        dao: () async => throw StateError('no database in this test'),
        observeLifecycle: false,
        watchConnectivity: false,
        startupDelay: const Duration(days: 1),
      ));
      reread.unseen.add(const VoucherRereadRecord(
        rereadId: 'VR-1',
        clientId: '1',
        pagePath: '',
        foundIds: ['97339', '700055555'], // the second is not open here
        status: VoucherRereadStatus.done,
      ));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: CollectionActivityAccountInvoicesScreen(client: _client),
      ));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('voucher-reread-text')))
              .data,
          'Online re-read found 1 more invoice: 97339');

      await tester.tap(find.byKey(const ValueKey('voucher-reread-select')));
      await tester.pumpAndSettle();
      expect(activity.selectedActivityInvoiceIds, {'97339'});
      expect(activity.voucherInvoiceIds, {'97339'});
      expect(find.byKey(const ValueKey('voucher-reread-banner')), findsNothing);
      reread.onClose(); // its startup timer
    });

    testWidgets('no camera: only Attach File', (tester) async {
      _seeded();
      Get.put(VoucherScanController(repository: _Ai().repository()));
      await tester.pumpWidget(GetMaterialApp(
          home: ScannedInvoicesScreen(client: _client, cameraAvailable: false)));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ButtonStyleButton>(
                  find.byKey(const ValueKey('scanner-capture')))
              .enabled,
          isFalse);
      expect(
          tester
              .widget<ButtonStyleButton>(
                  find.byKey(const ValueKey('scanner-attach')))
              .enabled,
          isTrue);
    });
  });

  group('document scanner', () {
    test('its pages are the scan', () async {
      final pages = await BVoucherFilePicker.takePhoto(
          scan: () async => [_photo, _pdf]);
      expect(pages, [_photo, _pdf]);
    });

    test('a cancelled scan is no scan, and no camera either', () async {
      expect(await BVoucherFilePicker.takePhoto(scan: () async => const []),
          isEmpty);
    });
  });
}
