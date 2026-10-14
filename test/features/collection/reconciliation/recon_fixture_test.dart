import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_rules.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

/// Every sample case in test/fixtures/reconciliation/sample_cases.json gives
/// the result written next to it. The backend's rules port reads the same
/// file, so the phone and the server cannot disagree about a case.

const _path = 'test/fixtures/reconciliation/sample_cases.json';

double? _num(dynamic v) => v is num ? v.toDouble() : null;

void main() {
  final fixture =
      jsonDecode(File(_path).readAsStringSync()) as Map<String, dynamic>;
  final now = DateTime.parse(fixture['now'] as String);
  final settings = ReconSettings(
      noResponseDays: (fixture['settings'] as Map)['noResponseDays'] as int);

  for (final raw in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test(raw['name'], () {
      final c = raw['case'] as Map<String, dynamic>;
      final reconCase = ReconCase(
        caseId: c['caseId'],
        clientCode: c['clientCode'],
        clientName: c['clientName'],
        collectorCode: c['collectorCode'],
        dateOpened: c['dateOpened'],
      );
      final invoices = [
        for (final i in (raw['invoices'] as List).cast<Map<String, dynamic>>())
          ReconCaseInvoice(
            invoiceNo: i['invoiceNo'],
            amount: _num(i['amount'])!,
            currentBalance: _num(i['currentBalance']),
            clearedAt: i['clearedAt'] as String?,
          ),
      ];
      final activities = [
        for (final a
            in (raw['activities'] as List).cast<Map<String, dynamic>>())
          ReconActivity(
            activityId: a['activityId'],
            caseId: reconCase.caseId,
            dateTime: a['dateTime'],
            type: ReconActivityType.fromCode(a['type'])!,
            invoiceNos: [...?(a['invoiceNos'] as List?)?.cast<String>()],
            remarks: a['remarks'] as String? ?? '',
            amount: _num(a['amount']),
            validationResult: ReconValidationResult.fromCode(
                a['validationResult'] as String?),
            nextAction: a['nextAction'] as String? ?? '',
            nextActionDueDate: a['nextActionDueDate'] as String?,
          ),
      ];

      final e = evaluateReconCase(
        reconCase: reconCase,
        invoices: invoices,
        activities: activities,
        now: now,
        settings: settings,
      );
      final expected = raw['expected'] as Map<String, dynamic>;

      expect(e.status.code, expected['status']);
      expect(e.nextActor?.code, expected['nextActor']);
      expect({for (final i in e.invoices) i.invoiceNo: i.status.code},
          expected['invoices']);
      expect(e.flags.map((f) => f.code).toSet(),
          (expected['flags'] as List).toSet());
      expect(e.warnings, hasLength(expected['warnings']),
          reason: e.warnings.join('\n'));
      if (expected.containsKey('soaAmount')) {
        expect(e.soaAmount, closeTo(_num(expected['soaAmount'])!, 0.001));
      }
      if (expected.containsKey('amountValidatedPaid')) {
        expect(e.amountValidatedPaid,
            closeTo(_num(expected['amountValidatedPaid'])!, 0.001));
      }
      if (expected.containsKey('amountUnderReconciliation')) {
        expect(e.amountUnderReconciliation,
            closeTo(_num(expected['amountUnderReconciliation'])!, 0.001));
      }
      if (expected.containsKey('dateClosed')) {
        expect(e.dateClosed, BReconClock.parse(expected['dateClosed']));
      }
      // Stages are keyed by the wire code of the step that completes each,
      // so the backend reads them without the phone's enum names.
      if (expected.containsKey('stages')) {
        expect({for (final p in e.stages) p.stage.type.code: p.count},
            expected['stages']);
      }
      if (expected.containsKey('currentStage')) {
        expect(e.currentStage?.type.code, expected['currentStage']);
      }
    });
  }
}
