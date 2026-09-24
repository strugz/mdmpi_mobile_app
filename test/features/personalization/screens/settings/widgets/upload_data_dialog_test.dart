import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/delivery_update_outcome.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_upload_summary.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/settings_department_theme.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/settings/widgets/upload_data_dialog.dart';

StandardDeliveryModel _request(String id) => StandardDeliveryModel(
      id: id,
      clientId: 'client-123',
      shippingMethod: 'Land',
      deliveryTerms: 'Full',
      deliveryDate: '2026-09-24',
      preference: 'Medium',
      status: 'Item Prepared',
      requestBy: 'MMA',
      createdBy: 'AMG',
      documentReference: const [],
      client: ClientModel.empty(),
      createdAt: '2026-09-24 08:00:00',
    );

Widget _host(ThemeData theme, UploadDataRunner upload,
        {bool reduceMotion = false}) =>
    MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showUploadDataDialog(context, upload: upload),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  test('Settings wears the department theme', () {
    expect(
        SettingsDepartmentTheme.forDepartment('Collection').colorScheme.primary,
        BCollectionColors.primary);
    expect(
        SettingsDepartmentTheme.forDepartment(' collection ')
            .colorScheme
            .primary,
        BCollectionColors.primary);
    expect(
        SettingsDepartmentTheme.forDepartment('Logistics').colorScheme.primary,
        BColors.primary);
    expect(SettingsDepartmentTheme.forDepartment('').colorScheme.primary,
        BColors.primary);
  });

  testWidgets('confirm → uploading with progress → result', (tester) async {
    final gate = Completer<void>();
    void Function(int, int)? report;

    await tester.pumpWidget(
        _host(SettingsDepartmentTheme.logistics, (onProgress) async {
      report = onProgress;
      final summary = await RequestUploadSummary.run(
        [_request('1'), _request('2')],
        (request) async {
          if (request.id == '2') await gate.future;
          return const DeliveryUpdateOutcome.updated();
        },
        onProgress: onProgress,
      );
      return Result.success(summary);
    }));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Upload data?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Upload'));
    // The arrow loops while uploading, so step time instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(report, isNotNull);
    expect(find.text('Uploading…'), findsOneWidget);
    expect(find.text('Request 2 of 2'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);

    // The back button cannot close it mid-upload.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Uploading…'), findsOneWidget);

    gate.complete();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Upload complete'), findsOneWidget);
    expect(find.text('Uploaded 2 requests.'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(UploadDataDialog), findsNothing);
  });

  testWidgets('a failed upload shows the error in Collection colours',
      (tester) async {
    await tester.pumpWidget(_host(SettingsDepartmentTheme.collection,
        (_) async => Result.failure('Could not upload requests: offline')));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Upload failed'), findsOneWidget);
    expect(find.text('Could not upload requests: offline'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
    final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator));
    expect(ring.value, 1);
    expect(ring.color, BCollectionColors.danger);
  });

  testWidgets('reduced motion keeps the arrow still', (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
        _host(SettingsDepartmentTheme.logistics, (onProgress) async {
      onProgress(0, 1);
      await gate.future;
      return Result.success(RequestUploadSummary());
    }, reduceMotion: true));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    gate.complete();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  });
}
