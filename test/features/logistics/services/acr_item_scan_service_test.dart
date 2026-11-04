import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/acr_verdict.dart';
import 'package:mdmpi_mobile_app/features/logistics/services/acr_item_scan_service.dart';

OcrLine _l(String text, double left, double top, double width) =>
    OcrLine(text, Rect.fromLTWH(left, top, width, 20));

/// A letterhead, a clean two-row table and a signature footer.
final _cleanPage = [
  _l('MARS M. DRYSDALE PHILS. INC.', 100, 40, 400),
  _l('Form ID: ITR-0042', 100, 80, 200),
  _l('Item Code', 105, 585, 97),
  _l('Description', 349, 585, 107),
  _l('Qty', 918, 585, 34),
  _l('Unit', 1031, 585, 40),
  _l('RXH60169', 105, 617, 97),
  _l('Optic Bench', 252, 617, 262),
  _l('1.00', 916, 617, 40),
  _l('PIECE', 1031, 617, 55),
  _l('RXH60170', 105, 650, 97),
  _l('Lamp Assy', 252, 650, 200),
  _l('2.00', 916, 650, 40),
  _l('BOX', 1031, 650, 40),
  _l('Prepared by: J. Cruz', 100, 1300, 300),
];

/// Same table, the second row's quantity and unit unread.
final _incompletePage = [
  for (final l in _cleanPage)
    if (l.text != '2.00' && l.text != 'BOX') l,
];

void main() {
  final photo = File('scan.jpg');
  final geminiItem = InventoryItemModel(
      itemCode: 'G1', description: 'From Gemini', qty: 3, unit: 'SET');

  late List<String> geminiFiles;
  late List<Rect> crops;

  AcrItemScanService service(
    List<OcrLine> lines, {
    Result<List<InventoryItemModel>>? gemini,
    bool onDevice = true,
    String? cropPath = 'crop.jpg',
  }) {
    geminiFiles = [];
    crops = [];
    return AcrItemScanService(
      readLines: (_) async => lines,
      readWithGemini: (file, {prompt}) async {
        geminiFiles.add(file.path);
        return gemini ?? Result.success([geminiItem]);
      },
      cropToRegion: (_, region) async {
        crops.add(region);
        return cropPath;
      },
      onDevice: onDevice,
      env: const {},
    );
  }

  test('a clean table is finished on the phone, Gemini never called',
      () async {
    final r = await service(_cleanPage).scan(photo);
    expect(r.isSuccess, isTrue);
    expect(r.value.source, AcrItemSource.acr);
    expect(r.value.items.map((i) => i.itemCode), ['RXH60169', 'RXH60170']);
    expect(geminiFiles, isEmpty);
  });

  test('a missing field sends only the table band to Gemini', () async {
    final r = await service(_incompletePage).scan(photo);
    expect(r.value.source, AcrItemSource.gemini);
    expect(r.value.items.single.description, 'From Gemini');
    expect(r.value.verdict.reasons, contains(AcrFallbackReason.missingFields));
    expect(geminiFiles, ['crop.jpg']);
    // Header row to last table line; letterhead and footer are outside.
    expect(crops.single.top, 585);
    expect(crops.single.bottom, 670);
  });

  test('an empty answer from the crop retries with the whole photo',
      () async {
    final r = await service(_incompletePage,
            gemini: Result.success(const []))
        .scan(photo);
    expect(r.isSuccess, isTrue);
    expect(geminiFiles, ['crop.jpg', 'scan.jpg']);
  });

  test('no table found sends the whole photo', () async {
    await service([_l('Just a letter', 100, 100, 300)]).scan(photo);
    expect(crops, isEmpty);
    expect(geminiFiles, ['scan.jpg']);
  });

  test('a PDF or a desktop goes straight to Gemini', () async {
    await service(_cleanPage).scan(File('doc.pdf'));
    expect(geminiFiles, ['doc.pdf']);
    await service(_cleanPage, onDevice: false).scan(photo);
    expect(geminiFiles, ['scan.jpg']);
  });

  test('Gemini unavailable keeps the phone reading, flagged', () async {
    final r = await service(_incompletePage,
            gemini: Result.failure('AI service error: 503'))
        .scan(photo);
    expect(r.isSuccess, isTrue);
    expect(r.value.source, AcrItemSource.acr);
    expect(r.value.aiError, 'AI service error: 503');
    expect(r.value.items, hasLength(2));
  });

  test('nothing read and Gemini unavailable is a failure', () async {
    final r = await service(const [],
            gemini: Result.failure('AI service error: 503'))
        .scan(photo);
    expect(r.isFailure, isTrue);
  });
}
