import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/delivery_update_outcome.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/upload_data_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/upload_data_page.dart';

StandardDeliveryModel _r(String id, String status, String client) =>
    StandardDeliveryModel(
      id: id,
      clientId: 'client-$id',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2026-09-24',
      preference: 'Medium',
      status: status,
      requestBy: 'MMA',
      createdBy: 'AMG',
      documentReference: const [],
      client: ClientModel(
          id: 'client-$id',
          name: client,
          address: '',
          contact: '',
          emailAddress: ''),
      createdAt: '2026-09-24 08:00:00',
    );

void main() {
  late List<String> sent;
  late List<String> replaced;
  late bool online;

  setUp(() {
    Get.testMode = true;
    sent = [];
    replaced = [];
    online = true;
    Get.put(UploadDataController(
      loadLocal: () async => [
        _r('1', 'For Delivery', 'Bps Enterprises'),
        _r('2', 'Item Prepared', 'Asia Medic'),
        _r('3', 'Item Prepared', 'Metroglobe'),
      ],
      loadServer: () async => [
        _r('1', 'Item Prepared', 'Bps Enterprises'),
        _r('2', 'Item Prepared', 'Asia Medic'),
        _r('3', 'Delivered', 'Metroglobe'),
      ],
      send: (request) async {
        sent.add(request.id);
        return const DeliveryUpdateOutcome.updated(
            'Request updated successfully.');
      },
      replaceLocal: (copy) async => replaced.add(copy.id),
      isOnline: () async => online,
      now: () => DateTime(2026, 9, 24, 10),
    ));
  });

  tearDown(Get.reset);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: UploadDataPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the header counts, the groups and the date filters',
      (tester) async {
    await open(tester);

    expect(find.text('Upload Data'), findsOneWidget);
    expect(find.text('Ready to upload'), findsOneWidget);
    // Header counts; the lower groups are built lazily off-screen.
    expect(find.text('Server ahead'), findsOneWidget);
    expect(find.text('Same status'), findsWidgets);
    expect(find.text('Bps Enterprises'), findsOneWidget);
    expect(find.text('Upload 1 request'), findsOneWidget);
    for (final label in ['All dates', 'Today', 'Tomorrow', 'Yesterday']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tapping the ready row unticks it', (tester) async {
    await open(tester);
    await tester.tap(find.text('Bps Enterprises'));
    await tester.pumpAndSettle();

    expect(find.text('Tick requests to upload'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('a date with no requests offers to show all dates',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();

    expect(find.text('No requests in this range'), findsOneWidget);
    await tester.tap(find.text('Show all dates'));
    await tester.pumpAndSettle();
    expect(find.text('Bps Enterprises'), findsOneWidget);
  });

  testWidgets('uploads only the ticked request and reports same status',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('Upload 1 request'));
    await tester.pumpAndSettle();
    expect(find.text('Upload 1 request?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Upload'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(sent, ['1']);
    expect(find.textContaining('1 request has the same status as the server.'),
        findsOneWidget);
  });

  testWidgets('offline shows a retry instead of the list', (tester) async {
    online = false;
    await open(tester);

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Bps Enterprises'), findsNothing);
  });

  testWidgets('a server-ahead row opens the side-by-side comparison',
      (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester);

    await tester.tap(find.text('Metroglobe'));
    await tester.pumpAndSettle();

    expect(find.text('The server is ahead'), findsOneWidget);
    expect(find.text('Phone'), findsWidgets);
    expect(find.text('Server'), findsWidgets);
    expect(find.text('Differences (1)'), findsOneWidget);
    // Differences only by default: the status row, not the untouched ones.
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Receiver'), findsNothing);

    await tester.tap(find.text('All fields (12)'));
    await tester.pumpAndSettle();
    expect(find.text('Receiver'), findsOneWidget);

    await tester.tap(find.text('Take server copy'));
    await tester.pumpAndSettle();
    expect(replaced, ['3']);
    expect(find.text('The server is ahead'), findsNothing);
  });

  testWidgets('the compare button opens it for a ready row too',
      (tester) async {
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester);

    await tester.tap(find.byTooltip('Compare with server').first);
    await tester.pumpAndSettle();

    expect(find.text('The phone is ahead'), findsOneWidget);
    // No take-server-copy for a request the phone is ahead on.
    expect(find.text('Take server copy'), findsNothing);
  });
}
