import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_document_scan_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/b_scan_first_action.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/common/scan/scan_source_sheet.dart';

/// Scan Document lives on Home only (2026-10-15); the request forms have no
/// scan button of their own.
void main() {
  tearDown(Get.reset);

  testWidgets('hidden off Android', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(body: BScanFirstAction(showOnThisPlatform: false)),
    ));
    expect(find.byKey(const Key('scanFirstAction')), findsNothing);
  });

  Future<DocumentScanSource?> Function() openSheet(
      WidgetTester tester, bool scanner) {
    return () async {
      DocumentScanSource? picked;
      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked = await ScanSourceSheet.show(
                  context,
                  scannerAvailable: scanner),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return picked;
    };
  }

  testWidgets('Android: the document scanner first, camera and gallery kept',
      (tester) async {
    await openSheet(tester, true)();
    expect(find.text('Scan document'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Pick from gallery'), findsOneWidget);
    final scannerY = tester.getTopLeft(find.text('Scan document')).dy;
    expect(scannerY, lessThan(tester.getTopLeft(find.text('Take a photo')).dy));
  });

  testWidgets('each choice returns its source', (tester) async {
    for (final (label, source) in [
      ('Scan document', DocumentScanSource.scanner),
      ('Take a photo', DocumentScanSource.camera),
      ('Pick from gallery', DocumentScanSource.gallery),
    ]) {
      DocumentScanSource? picked;
      await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked =
                  await ScanSourceSheet.show(context, scannerAvailable: true),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(picked, source, reason: label);
    }
  });

  testWidgets('without the scanner (off Android) only camera and gallery',
      (tester) async {
    await openSheet(tester, false)();
    expect(find.text('Scan document'), findsNothing);
    expect(find.text('Take a photo'), findsOneWidget);
  });
}
