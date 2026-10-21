import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_header_extractor.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/item_table_parser.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/ocr_line_dump.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/one_scan_reference_patterns.dart';

/// Runs the one-scan readers over real OCR dumps from the phone (Settings >
/// Developer Tools > Dump OCR lines), copied into `test/fixtures/one_scan/`.
/// That folder is git-ignored (customer data), so on a clean checkout or in
/// CI this test is skipped. Fill in a fixture's `expected` block to have it
/// checked; without one, the fixture only has to yield something.
void main() {
  test('dump JSON round-trips', () {
    final lines = [
      OcrLine('Business Partner:', const Rect.fromLTWH(55, 252, 163, 20),
          angle: 0.5,
          cornerPoints: const [Offset(55, 252), Offset(218, 252)]),
      OcrLine('DLR-190', const Rect.fromLTWH(55, 284, 80, 20)),
    ];
    final json = jsonDecode(jsonEncode(
        OcrLineDump.toJson(lines, source: 'IMG_1.jpg')))
        as Map<String, dynamic>;
    final back = OcrLineDump.linesFromJson(json);
    expect(back.map((l) => l.text), ['Business Partner:', 'DLR-190']);
    expect(back.first.box, lines.first.box);
    expect(back.first.angle, 0.5);
    expect(back.first.cornerPoints, lines.first.cornerPoints);
    expect(back.last.angle, isNull);
    expect(json['source'], 'IMG_1.jpg');
  });

  final dir = Directory('test/fixtures/one_scan');
  final files = dir.existsSync()
      ? (dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
        ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  group('device OCR fixtures', () {
    for (final file in files) {
      test(file.uri.pathSegments.last, () {
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final lines = OcrLineDump.linesFromJson(json);
        final header = ClientHeaderExtractor.extract(lines);
        final items = ItemTableParser.parse(lines);
        final refs = OneScanReferencePatterns.fromLines(
            lines, DocumentReferenceExtractor(),
            excludeTexts: items.tableTexts);

        final expected = (json['expected'] as Map?) ?? const {};
        if (expected.containsKey('name')) {
          expect(header.name, expected['name'], reason: 'client name');
        }
        if (expected.containsKey('address')) {
          expect(header.address, expected['address'], reason: 'address');
        }
        if (expected.containsKey('references')) {
          expect(refs, containsAll(expected['references'] as List),
              reason: 'references');
        }
        if (expected.containsKey('items')) {
          expect(items.items.length, expected['items'], reason: 'item count');
        }
        if (expected.containsKey('batches')) {
          expect(items.items.fold<int>(0, (n, i) => n + i.batches.length),
              expected['batches'], reason: 'batch count');
        }
        if (expected.isEmpty) {
          expect(header.hasLabel || refs.isNotEmpty || items.headerFound, isTrue,
              reason: 'read nothing from ${json['source']}');
        }
      });
    }
  }, skip: files.isEmpty ? 'no OCR dumps in test/fixtures/one_scan' : false);
}
