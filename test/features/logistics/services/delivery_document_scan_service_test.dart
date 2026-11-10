import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_alias_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/client/client_alias_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_matcher.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/client_match_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/delivery_document_scan_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

OcrLine _l(String text, double left, double top, double width,
        {double? angle}) =>
    OcrLine(text, Rect.fromLTWH(left, top, width, 20), angle: angle);

/// The Stock Issue Slip (S2), upright.
final _upright = [
  _l('STOCK ISSUE SLIP', 700, 305, 545),
  _l('No. 00611', 1605, 318, 305),
  _l('DELIVERED TO:', 60, 402, 203),
  _l('QUEZON CITY GENERAL HOSPITAL', 320, 405, 548),
  _l('QTY', 95, 545, 50),
  _l('ITEM DESCRIPTION', 710, 545, 252),
  _l('1', 128, 617, 10),
  _l('BT120 Auto Blood Culture Analyzer', 550, 617, 430),
];

/// The same page read sideways: garbled, every line at about +90°.
final _sideways = [
  for (final t in ['3dIS', 'n0lz', 'dwq', 'xx'])
    _l(t, 10, 10, 20, angle: 90),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ClientMatcher matcher;
  final clients = [
    ClientModel(
        id: '5',
        name: 'QUEZON CITY GENERAL HOSPITAL',
        address: 'Seminary Road',
        contact: '',
        emailAddress: ''),
    ClientModel(
        id: '9',
        name: 'Galinato Clinic And Hospital',
        address: 'EXCELSIS LABORATORY & DIAGNOSTIC TRADING',
        contact: '',
        emailAddress: ''),
  ];

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, v) async {
      await db.execute('CREATE TABLE ACCMST_ (ACCMID TEXT, ACCMNM TEXT)');
      await ensureOneScanTables(db);
    });
    final dao = ClientAliasDao(db);
    matcher = ClientMatcher(
        aliases: ClientAliasRepository(dao: () async => dao));
  });

  tearDown(() async => db.close());

  DeliveryDocumentScanService service(
    Map<String, List<OcrLine>> pages,
    List<(String, int)> rotations,
  ) =>
      DeliveryDocumentScanService(
        textExtractor: DocumentReferenceExtractor(),
        matcher: matcher,
        clients: () async => clients,
        readLines: (path) async {
          final lines = pages[path];
          if (lines == null) throw StateError('cannot read $path');
          return lines;
        },
        rotateForRetry: (path, rotation) async {
          rotations.add((path, rotation));
          return 'rotated';
        },
      );

  test('pass 1 is enough: client, references and items from one read',
      () async {
    final rotations = <(String, int)>[];
    final r = await service({'photo': _upright}, rotations).scan(File('photo'));

    expect(rotations, isEmpty);
    final v = r.value;
    expect(v.header.name, 'QUEZON CITY GENERAL HOSPITAL');
    expect(v.match.kind, ClientMatchKind.exact);
    expect(v.match.candidates.first.client.id, '5');
    expect(v.references, contains('SIS#:00611'));
    expect(v.items.items.single.description, 'BT120 Auto Blood Culture Analyzer');
    expect(v.retryRotation, isNull);
  });

  test('no retry when only a reference was found', () async {
    final rotations = <(String, int)>[];
    await service({
      'photo': [
        _l('GI No.: 760006490', 0, 0, 200, angle: 90),
        ..._sideways,
      ]
    }, rotations)
        .scan(File('photo'));
    expect(rotations, isEmpty);
  });

  test('no retry when only an item table was found', () async {
    final rotations = <(String, int)>[];
    await service({
      'photo': [
        _l('QTY', 0, 0, 40, angle: 90),
        _l('DESCRIPTION', 100, 0, 120, angle: 90),
        ..._sideways,
      ]
    }, rotations)
        .scan(File('photo'));
    expect(rotations, isEmpty);
  });

  test('a sideways page is retried exactly once, at the estimated angle',
      () async {
    final rotations = <(String, int)>[];
    final svc = service({'photo': _sideways, 'rotated': _upright}, rotations);
    final r = await svc.scan(File('photo'));

    expect(rotations, [('photo', 270)]);
    expect(svc.lastLines, _upright,
        reason: 'the dump tool saves the pass that was used');
    expect(r.value.retryRotation, 270);
    expect(r.value.header.name, 'QUEZON CITY GENERAL HOSPITAL');
    expect(r.value.warnings, isEmpty);
  });

  test('an upright but unreadable page is not retried; asks for a retake',
      () async {
    final rotations = <(String, int)>[];
    final r = await service({
      'photo': [for (final t in ['blur', 'smudge', 'x']) _l(t, 0, 0, 10, angle: 1)]
    }, rotations)
        .scan(File('photo'));

    expect(rotations, isEmpty);
    expect(r.value.foundNothing, isTrue);
    expect(r.value.warnings.single, contains('Try a straighter photo'));
  });

  test('when the retry finds nothing either, the fuller reading is kept',
      () async {
    final rotations = <(String, int)>[];
    final r = await service({
      'photo': _sideways,
      'rotated': [_l('?', 0, 0, 10)],
    }, rotations)
        .scan(File('photo'));

    expect(rotations, hasLength(1));
    expect(r.value.foundNothing, isTrue);
    expect(r.value.warnings.single, contains('Try a straighter photo'));
  });

  test('an OCR failure is a Result failure, not a throw', () async {
    final r = await service({}, []).scan(File('missing'));
    expect(r.isFailure, isTrue);
  });

  group('Inventory Transfer (device run 2026-10-15)', () {
    /// The IT page with its "Business Partner:" label misread, so no name
    /// is found under a label; comments name an AR code.
    final page = [
      _l('MARSMAN DRYSDALE', 205, 140, 335),
      _l('INVENTORY TRANSFER', 978, 300, 462),
      _l('Buslness Partnor', 48, 320, 160),
      _l('DLR-190', 48, 350, 76),
      _l('Galinato Clinic and Hospital', 170, 350, 250),
      _l('TIN: 194-402-270-000', 48, 380, 198),
      _l('IT No.:', 908, 400, 62),
      _l('750005578', 908, 448, 100),
      _l('Contact Person: Mr. Tito V. Reyes', 48, 487, 305),
      _l('Transfer Request No.: ITR 810003436', 908, 497, 400),
      _l('Address:', 48, 545, 82),
      _l('Villamor, Esperanza Sultran Kudarat', 48, 577, 330),
      _l('Item Code', 100, 668, 97),
      _l('Description', 487, 668, 105),
      _l('RXH60035', 103, 700, 95),
      _l('RBC Counting Chamber', 248, 700, 212),
      _l('Comments:', 72, 1475, 100),
      _l('ACD thru viber1750 AR26-239 Galincato Clinic and Hospital', 72, 1508, 700),
    ];

    test('the client is found from the header rows when the label is misread',
        () async {
      final r = await service({'photo': page}, []).scan(File('photo'));
      final v = r.value;
      expect(v.header.name, 'Galinato Clinic and Hospital');
      expect(v.match.candidates.first.client.id, '9');
      expect(v.warnings, isNot(contains(startsWith("Couldn't read the client"))));
    });

    test('only the IT No. and ITR No. are kept, not the AR code in the comments',
        () async {
      final r = await service({'photo': page}, []).scan(File('photo'));
      expect(r.value.references, ['ITNo.:750005578', 'ITRNo.:810003436']);
    });

    test('no header row matching a client keeps the search', () async {
      final r = await service({
        'photo': [
          for (final l in page)
            if (!l.text.contains('Galinato')) l,
        ]
      }, []).scan(File('photo'));
      expect(r.value.header.hasName, isFalse);
      expect(r.value.match.candidates, isEmpty);
      expect(r.value.warnings, contains(startsWith("Couldn't read the client")));
    });
  });

  test('a page with no item table says so but keeps client and references',
      () async {
    final r = await service({
      'photo': [
        _l('DELIVERED TO:', 60, 402, 203),
        _l('QUEZON CITY GENERAL HOSPITAL', 320, 405, 548),
        _l('GI No.: 760006490', 900, 500, 200),
      ]
    }, [])
        .scan(File('photo'));
    expect(r.value.header.hasName, isTrue);
    expect(r.value.references, ['GINo.:760006490']);
    expect(r.value.warnings, ['No item table found. Use Add Item for the items.']);
  });
}
