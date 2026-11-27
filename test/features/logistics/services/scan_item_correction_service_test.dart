import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/data/local/dao/common/scan_item_vocab_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/inventory/scan_item_vocabulary_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/scan_item_correction_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late List<Uri> calls;
  late http.Response Function(Uri) answer;
  late ScanItemCorrectionService service;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, v) async => createAllTables(db));
    calls = [];
    answer = (_) => http.Response('[]', 200);
    service = ScanItemCorrectionService(ScanItemVocabularyRepository(
      dao: () async => ScanItemVocabDao(db),
      get: (uri) async {
        calls.add(uri);
        return answer(uri);
      },
    ));
  });

  tearDown(() async => db.close());

  ItemTableReading reading(String desc, [String code = '']) => ItemTableReading(
        headerFound: true,
        items: [InventoryItemModel(itemCode: code, description: desc, qty: 1, unit: '')],
      );

  test('not known locally: asks the server once, saves, corrects', () async {
    answer = (_) => http.Response(
        jsonEncode([
          {'ItemCode': 'B36868', 'Description': 'Lyse Bottle 1L', 'Unit': 'BOTTLE', 'Uses': 7},
        ]),
        200);

    final (out, missed) = await service.correct(reading('Lyse 80ttle 1L'));
    expect(out.items.single.description, 'Lyse Bottle 1L');
    expect(missed, isFalse);
    expect(calls, hasLength(1));
    expect(calls.single.path, '/api4/Item/vocabulary');
    expect(calls.single.queryParameters['words'], contains('bottle'));

    // Known now: no second call.
    final (again, _) = await service.correct(reading('Lyse 80ttle 1L'));
    expect(again.items.single.description, 'Lyse Bottle 1L');
    expect(calls, hasLength(1));
  });

  test('server down: reading kept, flagged, asked again next time', () async {
    answer = (_) => throw const SocketExceptionStub();
    final (out, missed) = await service.correct(reading('Unknown Thing'));
    expect(out.items.single.description, 'Unknown Thing');
    expect(missed, isTrue);
    await service.correct(reading('Unknown Thing'));
    expect(calls, hasLength(2));
  });

  test('items confirmed on the form are known on the next scan', () async {
    await service.learn([
      InventoryItemModel(itemCode: '', description: 'Hemolyzer Tube', qty: 1, unit: ''),
    ]);
    final (out, _) = await service.correct(reading('Hemo1yzer Tube'));
    expect(out.items.single.description, 'Hemolyzer Tube');
    expect(calls, isEmpty);
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
