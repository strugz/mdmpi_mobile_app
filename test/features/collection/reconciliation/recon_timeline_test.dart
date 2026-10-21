import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/reconciliation/recon_case_screen.dart';

/// A case's timeline: the logged steps plus a Settled line for each invoice
/// paid off, worked out on the phone (nothing is uploaded for it).

final _now = DateTime.parse('2026-10-20T10:00:00+08:00');

ReconActivity _step(String id, ReconActivityType type, String at,
        {List<String> invoices = const [],
        ReconValidationResult? result}) =>
    ReconActivity(
        activityId: id,
        caseId: 'RC-1',
        dateTime: at,
        type: type,
        invoiceNos: invoices,
        validationResult: result);

ReconCaseBundle _bundle(List<ReconCaseInvoice> invoices,
        List<ReconActivity> steps) =>
    ReconCaseBundle(
      reconCase: const ReconCase(
          caseId: 'RC-1',
          clientCode: 'NLN-1',
          clientName: 'Amka Trading',
          collectorCode: 'JCA',
          collectorName: 'Jay',
          dateOpened: '2026-10-01T09:00:00'),
      invoices: invoices,
      activities: steps,
    );

List<String> _labels(ReconCaseBundle b) => [
      for (final t in timelineEntries(b.activities, b.evaluate(now: _now)))
        t.activity?.type.code ?? 'SETTLED ${t.settled!.invoiceNo}',
    ];

void main() {
  test('nothing paid off: only the logged steps, newest first', () {
    final b = _bundle(const [
      ReconCaseInvoice(invoiceNo: 'A', amount: 100),
    ], [
      _step('1', ReconActivityType.soaSent, '2026-10-02T09:00:00'),
      _step('2', ReconActivityType.followUp, '2026-10-05T09:00:00'),
    ]);
    expect(_labels(b), ['FOLLOW_UP', 'SOA_SENT']);
  });

  test('a balance at zero settles the invoice when the server saw it', () {
    final b = _bundle(const [
      ReconCaseInvoice(
          invoiceNo: 'A',
          amount: 100,
          currentBalance: 0,
          clearedAt: '2026-10-03T14:00:00'),
      ReconCaseInvoice(invoiceNo: 'B', amount: 50),
    ], [
      _step('1', ReconActivityType.soaSent, '2026-10-02T09:00:00'),
      _step('2', ReconActivityType.followUp, '2026-10-05T09:00:00'),
    ]);
    expect(_labels(b), ['FOLLOW_UP', 'SETTLED A', 'SOA_SENT']);
  });

  test('paid here before a download: Settled follows the payment', () {
    final b = _bundle(const [
      ReconCaseInvoice(invoiceNo: 'A', amount: 100, currentBalance: 0),
    ], [
      _step('1', ReconActivityType.soaSent, '2026-10-02T09:00:00'),
      _step('2', ReconActivityType.paymentRecorded, '2026-10-04T11:00:00',
          invoices: ['A']),
    ]);
    expect(_labels(b), ['SETTLED A', 'PAYMENT_RECORDED', 'SOA_SENT'],
        reason: 'same moment as the payment; it reads after it');
  });

  test('validated proof settles the invoice at the validation', () {
    final b = _bundle(const [
      ReconCaseInvoice(invoiceNo: 'A', amount: 100),
    ], [
      _step('1', ReconActivityType.soaSent, '2026-10-02T09:00:00'),
      _step('2', ReconActivityType.paidClaim, '2026-10-03T09:00:00',
          invoices: ['A']),
      _step('3', ReconActivityType.proofProvided, '2026-10-04T09:00:00',
          invoices: ['A']),
      _step('4', ReconActivityType.proofValidated, '2026-10-05T09:00:00',
          invoices: ['A'], result: ReconValidationResult.valid),
    ]);
    final labels = _labels(b);
    expect(labels.first, 'SETTLED A');
    expect(labels[1], 'PROOF_VALIDATED');
    final e = b.evaluate(now: _now);
    expect(e.invoices.single.status, ReconInvoiceStatus.validatedPaid,
        reason: 'the list keeps its own word for it');
  });
}
