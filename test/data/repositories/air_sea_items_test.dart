import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/local/dao/air_sea/air_sea_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/repositories/air_sea/air_sea_repository.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_message_template_service.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_payload_builder.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Air / Sea / Land items (plan LOGISTICS_AIR_SEA_ITEMS_PLAN.md): the create
/// body is unchanged, items follow in a second call to the shared item
/// endpoint (as Pull Out), and the New Request SMS lists them.

AirSeaModel _request() => AirSeaModel(
      clientId: 'C-1',
      status: 'New Request',
      createdBy: 'JCA',
      documentReference: const ['SINo.:700014771'],
      datePickUp: '2026-10-16',
      shippingMethod: 'Air',
    );

final _items = [
  InventoryItemModel(
    itemCode: 'B36845',
    description: 'DxH 500 Diluent, 10L',
    qty: 6,
    unit: 'BOX',
    batches: [
      InventoryBatchModel(
          batchSerial: '0179170', batchQuantity: 6, expiryDate: '07/18/2027'),
    ],
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AirSeaRepository.insert', () {
    late Database db;
    late AirSeaRepository repo;
    late List<(String, Object?)> posts;
    late Map<String, http.Response> answers;
    late List<String> warnings;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, v) async => createAllTables(db));
      posts = [];
      warnings = [];
      answers = {
        'RequestAirSea': http.Response(jsonEncode({'requestID': '202610150042'}), 201),
        'Item/request': http.Response('', 200),
      };
      repo = AirSeaRepository()
        ..daoForTesting = AirSeaDao(db)
        ..warningForTest = warnings.add
        ..postJsonForTest = (url, body) async {
          posts.add((url.path, jsonDecode(body)));
          final key = answers.keys.firstWhere((k) => url.path.contains(k));
          return answers[key]!;
        };
    });

    tearDown(() async => db.close());

    test('no items: exactly today\'s single create call', () async {
      await repo.insert(_request(), silent: true);
      expect(posts, hasLength(1));
      expect(posts.single.$1, endsWith('/api4/RequestAirSea'));
      expect((posts.single.$2 as Map).containsKey('items'), isFalse,
          reason: 'the create body never changes');
      expect(warnings, isEmpty);
    });

    test('items go to the shared item endpoint after the 201',
        () async {
      await repo.insert(_request(), silent: true, items: _items);
      expect(posts.map((p) => p.$1), [
        endsWith('/api4/RequestAirSea'),
        endsWith('/api4/Item/request/202610150042'),
      ]);
      expect((posts.first.$2 as Map).containsKey('items'), isFalse);
      expect(posts.last.$2, [_items.single.toJson()]);
    });

    test('an item post that fails keeps the request and does not throw',
        () async {
      answers['Item/request'] = http.Response('boom', 500);
      await repo.insert(_request(), silent: true, items: _items);
      expect(posts, hasLength(2));
      expect(await db.query('a_tblRequestAirSea'), hasLength(1),
          reason: 'the request was created and cached');
      expect(warnings.single, contains('items could not be saved'));
    });

    test('no request id in the response: items are not posted', () async {
      answers['RequestAirSea'] = http.Response('{}', 201);
      await repo.insert(_request(), silent: true, items: _items);
      expect(posts, hasLength(1));
      expect(warnings.single, contains('did not return its ID'));
    });
  });

  group('Air/Sea New Request SMS', () {
    final template = SmsMessageTemplateService();

    test('lists the items, as Standard Delivery does', () async {
      final payload = await const SmsPayloadBuilder()
          .build(BTexts.statusNewRequest, _request(), inventoryItems: _items);
      expect(payload!.inventoryItems, _items);
      final text = template.createMessage(BTexts.statusNewRequest, payload);
      expect(text, contains('Items:'));
      expect(text, contains('DxH 500 Diluent, 10L'));
    });

    test('no items: the message is as before', () async {
      final payload = await const SmsPayloadBuilder()
          .build(BTexts.statusNewRequest, _request());
      expect(payload!.inventoryItems, isEmpty);
      expect(template.createMessage(BTexts.statusNewRequest, payload),
          isNot(contains('Items:')));
    });

    test('status updates never carry items', () async {
      final payload = await const SmsPayloadBuilder()
          .build(BTexts.statusItemPacked, _request());
      expect(payload!.inventoryItems, isEmpty);
    });
  });
}
