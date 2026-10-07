import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_workspace_parser.dart';
import 'package:mdmpi_mobile_app/features/collection/mappers/recon_case_mapper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_case_bundle.dart';
import 'package:mdmpi_mobile_app/features/collection/models/reconciliation/recon_enums.dart';

/// `ReconCases` in the workspace download, as MDMPI.App sends it
/// (CollectionReconCaseDto), into the phone's case bundles.

Map<String, dynamic> _serverCase() => {
      'CaseId': 'RC-JCA-1',
      'ClientCode': 'NLN-115',
      'ClientName': 'Accusure Medical Enterprises',
      'CollectorCode': 'JCA',
      'CollectorName': 'Jay',
      'DateOpened': '2026-09-20T09:00:00',
      'DateClosed': null,
      'CaseStatus': 'WAITING_FOR_COLLECTOR',
      'NextActor': 'COLLECTOR',
      'Invoices': [
        {
          'DocumentId': '700013391',
          'Amount': 24281.25,
          'CurrentBalance': 24281.25,
          'ClearedAt': null
        },
        {
          'DocumentId': '700013392',
          'Amount': 121208.04,
          'CurrentBalance': 0,
          'ClearedAt': '2026-09-25T14:00:00'
        },
      ],
      'Activities': [
        {
          'ActivityId': 'RA-JCA-1',
          'DateTime': '2026-09-20T09:15:00',
          'Type': 'SOA_SENT',
          'DoneBy': 'COLLECTOR',
          'DocumentIds': <String>[],
          'Remarks': 'Emailed',
          'Amount': 145489.29,
          'ValidationResult': null,
          'NextAction': 'Follow up',
          'NextActionDueDate': '2026-09-27',
          'AttachmentIds': ['RP-1'],
          'RecordedBy': 'JCA',
        },
        {
          'ActivityId': 'RA-JCA-2',
          'DateTime': '2026-09-23T11:00:00',
          'Type': 'PROOF_VALIDATED',
          'DocumentIds': ['700013391'],
          'ValidationResult': 'VALID',
        },
      ],
    };

void main() {
  group('ReconCaseMapper', () {
    test('a full case', () {
      final b = ReconCaseMapper.fromJson(_serverCase())!;
      expect(b.source, ReconSource.server);
      expect(b.reconCase.caseId, 'RC-JCA-1');
      expect(b.reconCase.clientName, 'Accusure Medical Enterprises');
      expect(b.reconCase.dateOpened, '2026-09-20T09:00:00');
      expect(b.invoices.map((i) => i.invoiceNo), ['700013391', '700013392']);
      expect(b.invoices.last.currentBalance, 0);
      expect(b.invoices.last.clearedAt, '2026-09-25T14:00:00');
      expect(b.invoices.first.clearedAt, isNull);

      final soa = b.activities.first;
      expect(soa.caseId, 'RC-JCA-1');
      expect(soa.type, ReconActivityType.soaSent);
      expect(soa.amount, 145489.29);
      expect(soa.nextActionDueDate, '2026-09-27');
      expect(soa.attachmentRefs, ['RP-1']);
      expect(b.activities.last.validationResult, ReconValidationResult.valid);
      expect(b.activities.last.invoiceNos, ['700013391']);
    });

    test('camelCase keys, strings for numbers, comma-joined lists', () {
      final b = ReconCaseMapper.fromJson({
        'caseId': 'RC-2',
        'clientCode': 'NCR-1',
        'invoices': [
          {'documentId': 'A', 'amount': '100.50', 'currentBalance': '0'},
        ],
        'activities': [
          {
            'activityId': 'RA-1',
            'dateTime': 'x',
            'type': 'PAID_CLAIM',
            'documentIds': 'A, B',
            'validationResult': 'invalid'
          },
        ],
      })!;
      expect(b.invoices.single.amount, 100.5);
      expect(b.invoices.single.currentBalance, 0);
      expect(b.activities.single.invoiceNos, ['A', 'B']);
      expect(
          b.activities.single.validationResult, ReconValidationResult.invalid);
    });

    test('missing and blank keys become blanks, not errors', () {
      final b =
          ReconCaseMapper.fromJson({'CaseId': 'RC-3', 'ClientCode': 'NCR-1'})!;
      expect(b.reconCase.clientName, '');
      expect(b.invoices, isEmpty);
      expect(b.activities, isEmpty);

      final withBlanks = ReconCaseMapper.fromJson({
        'CaseId': 'RC-4',
        'ClientCode': 'NCR-1',
        'Invoices': [
          {'DocumentId': ''},
          {'DocumentId': 'B', 'Amount': null, 'CurrentBalance': ''},
          'not a map',
        ],
        'Activities': [
          {
            'ActivityId': 'RA-1',
            'Type': 'SOA_SENT',
            'NextActionDueDate': '  ',
            'Remarks': null
          },
        ],
      })!;
      expect(withBlanks.invoices.single.invoiceNo, 'B');
      expect(withBlanks.invoices.single.amount, 0);
      expect(withBlanks.invoices.single.currentBalance, isNull,
          reason: 'no balance known is not a zero balance');
      expect(withBlanks.activities.single.nextActionDueDate, isNull);
      expect(withBlanks.activities.single.remarks, '');
    });

    test('a case without an id or account is dropped', () {
      expect(ReconCaseMapper.fromJson({'ClientCode': 'NCR-1'}), isNull);
      expect(ReconCaseMapper.fromJson({'CaseId': 'RC-5', 'ClientCode': ' '}),
          isNull);
    });

    test('a step of a type this build does not know is left out', () {
      final b = ReconCaseMapper.fromJson({
        'CaseId': 'RC-6',
        'ClientCode': 'NCR-1',
        'Activities': [
          {'ActivityId': 'RA-1', 'Type': 'SOMETHING_NEWER'},
          {'ActivityId': '', 'Type': 'NOTE'},
          {'ActivityId': 'RA-3', 'Type': 'NOTE'},
        ],
      })!;
      expect(b.activities.map((a) => a.activityId), ['RA-3']);
    });
  });

  group('the workspace parser', () {
    test('reads ReconCases and says it was sent', () {
      final ws = CollectionWorkspaceParser.parse({
        'Items': [],
        'ReconCases': [
          _serverCase(),
          {'CaseId': ''}
        ],
      });
      expect(ws.hasReconCases, isTrue);
      expect(ws.reconCases.map((b) => b.caseId), ['RC-JCA-1']);
    });

    test('an empty list is sent; a missing key is an older server', () {
      expect(CollectionWorkspaceParser.parse({'ReconCases': []}).hasReconCases,
          isTrue);
      final old = CollectionWorkspaceParser.parse({'Items': []});
      expect(old.hasReconCases, isFalse,
          reason: 'must not read as "the server has no cases" and wipe them');
      expect(old.reconCases, isEmpty);
    });
  });
}
