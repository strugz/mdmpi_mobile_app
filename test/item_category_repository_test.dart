import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/repositories/common/item_category_repository.dart';

void main() {
  test('ItemCategoryRepository parses sample API and filters ITEM types', () async {
    final sample = jsonEncode([
      {"id": 1, "category": "Reagents", "type": "ITEM"},
      {"id": 2, "category": "Instrument", "type": "ITEM"},
      {"id": 3, "category": "Accessories", "type": "ITEM"},
      {"id": 4, "category": "Pull Out / Return", "type": "FORM"},
      {"id": 5, "category": "Pick Up", "type": "FORM"}
    ]);

    final client = MockClient((req) async => http.Response(sample, 200, headers: {'content-type': 'application/json'}));

    final repo = ItemCategoryRepository();
    // Use the injected client
    final items = await repo.getAll(client: client);

    expect(items.length, 3);
    expect(items.map((e) => e.name).toList(), containsAll(['Reagents', 'Instrument', 'Accessories']));
  });
}

