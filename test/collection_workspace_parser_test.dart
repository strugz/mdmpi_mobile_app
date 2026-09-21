import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_workspace_parser.dart';

/// Stage C3: the one-call workspace download is translated into device records.
void main() {
  final sample = <String, dynamic>{
    'Items': [
      {
        'id': 'INV-1',
        'Client': {'ACCMID': 'NCR-205', 'ACCMSC': 'NCR-205', 'ACCMNM': 'Abbott Laboratories'},
        'DocumentReferences': ['INV-1'],
        'ToBeCollected': 600,
        'TotalCollected': 400,
        'Status': '',
        'History': [
          {'Date': '2026-09-15', 'CollectorName': 'Juan', 'Status': 'Partially Collected', 'TotalCollected': 400, 'CheckNumber': '777'},
        ],
      },
    ],
    'Advances': [
      {'ExternalRef': 'AP-1001', 'PaymentId': 7, 'ClientCode': 'VIS-777', 'ClientName': 'Cebu Clinic', 'Amount': 5000, 'Unallocated': 2000, 'Date': '2026-09-15', 'Remarks': 'October', 'CollectorCode': 'EMP1'},
      {'ExternalRef': '', 'Amount': 1}, // no ref -> ignored
    ],
    'Deposits': [
      {'DepositId': 3, 'ClientCode': 'NCR-300', 'ClientName': 'Metro Globe', 'Date': '2026-09-15', 'BankName': 'BDO', 'ReferenceNo': 'C-900', 'Amount': 900, 'Remarks': '', 'CollectorCode': 'EMP1'},
    ],
    'Activities': [
      {'ActivityId': 9, 'Type': 'CWT Pick-up', 'ClientCode': 'SLN-050', 'ClientName': 'Palawan', 'Date': '2026-09-15', 'Remarks': '2307', 'CollectorCode': 'EMP1'},
    ],
    'AccountHistory': [
      {'ClientCode': 'NLN-115', 'Date': '2026-09-15', 'Status': 'Follow Up', 'Remarks': 'Call Monday', 'CollectorName': 'Juan'},
    ],
    'Targets': [
      {'YearMonth': '2026-09', 'TargetAmount': 150000},
    ],
  };

  test('parses every section of the workspace into device records', () {
    final ws = CollectionWorkspaceParser.parse(sample);

    final item = ws.items.single;
    expect(item.id, 'INV-1');
    expect(item.client.name, 'Abbott Laboratories');
    expect(item.toBeCollected, 600);
    expect(item.history.single.checkNumber, '777');

    final adv = ws.advances.single; // the ref-less one is dropped
    expect(adv.externalRef, 'AP-1001');
    expect(adv.amount, 2000, reason: 'the amount still available to assign is the unallocated remainder');
    expect(adv.isUnassigned, isTrue);

    expect(ws.activities.length, 2);
    final dep = ws.activities.firstWhere((a) => a.type == 'Deposit');
    expect(dep.clientName, 'Metro Globe');
    expect(dep.checkNumber, 'C-900');
    expect(dep.amount, 900);
    expect(dep.localRef, 'SRV-DEP-3');
    expect(ws.activities.any((a) => a.type == 'CWT Pick-up' && a.clientId == 'SLN-050'), isTrue);

    final h = ws.accountHistory.single;
    expect(h.clientId, 'NLN-115');
    expect(h.reason, 'Follow Up');

    expect(ws.targets, {'2026-09': 150000});
  });

  test('tolerates camelCase keys', () {
    final ws = CollectionWorkspaceParser.parse({
      'items': [],
      'advances': [
        {'externalRef': 'AP-2', 'clientCode': 'MIN-010', 'clientName': 'Davao', 'amount': 1000, 'unallocated': 1000, 'date': '2026-09-16', 'collectorCode': 'EMP1'},
      ],
      'targets': [
        {'yearMonth': '2026-10', 'targetAmount': 80000},
      ],
    });
    expect(ws.advances.single.externalRef, 'AP-2');
    expect(ws.targets['2026-10'], 80000);
  });

  test('missing sections yield empty collections, not errors', () {
    final ws = CollectionWorkspaceParser.parse({'Items': []});
    expect(ws.items, isEmpty);
    expect(ws.advances, isEmpty);
    expect(ws.activities, isEmpty);
    expect(ws.accountHistory, isEmpty);
    expect(ws.targets, isEmpty);
  });
}
