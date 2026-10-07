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

  // Revisions item 11: Actual Collection as the office posts it.
  group('ActualCollections', () {
    Map<String, dynamic> row(Map<String, dynamic> over) => {
          'ActualId': 41,
          'CollectionDate': '2026-09-12',
          'Amount': 15250.5,
          'ReferenceNo': 'OR 12345',
          'Remarks': 'BDO deposit slip',
          'PostedBy': 'Ana (Office)',
          'CreatedAt': '2026-09-12T09:30:00',
          'UpdatedAt': null,
          'UpdatedBy': null,
          ...over,
        };

    test('parses a posted entry, field for field', () {
      final ws = CollectionWorkspaceParser.parse({
        'ActualCollections': [row({})],
      });
      expect(ws.hasActualCollections, isTrue);
      final a = ws.actualCollections.single;
      expect(a.actualId, 41);
      expect(a.collectionDate, '2026-09-12');
      expect(a.amount, 15250.5);
      expect(a.referenceNo, 'OR 12345');
      expect(a.remarks, 'BDO deposit slip');
      expect(a.postedBy, 'Ana (Office)');
      expect(a.createdAt, '2026-09-12T09:30:00');
      expect(a.updatedAt, isNull);
      expect(a.updatedBy, isNull);
    });

    test('an older server that does not send the list is not an empty list',
        () {
      final ws = CollectionWorkspaceParser.parse({'Items': []});
      expect(ws.hasActualCollections, isFalse,
          reason: 'absent must leave the local copy alone');
      expect(ws.actualCollections, isEmpty);
    });

    test('a sent empty list is present, so it replaces the local copy', () {
      final ws = CollectionWorkspaceParser.parse({'ActualCollections': []});
      expect(ws.hasActualCollections, isTrue);
      expect(ws.actualCollections, isEmpty);
    });

    test('tolerates camelCase and a null list', () {
      final camel = CollectionWorkspaceParser.parse({
        'actualCollections': [
          {'actualId': 7, 'collectionDate': '2026-08-01', 'amount': 100},
        ],
      });
      expect(camel.actualCollections.single.actualId, 7);

      final nulled = CollectionWorkspaceParser.parse({'ActualCollections': null});
      expect(nulled.hasActualCollections, isFalse);
    });

    test('reads the amount as a number or a string', () {
      final ws = CollectionWorkspaceParser.parse({
        'ActualCollections': [
          row({'ActualId': 1, 'Amount': 900}),
          row({'ActualId': 2, 'Amount': '1250.75'}),
          row({'ActualId': 3, 'Amount': 'n/a'}),
        ],
      });
      expect(ws.actualCollections.map((a) => a.amount), [900, 1250.75, 0]);
    });

    test('skips rows it cannot keep, and keeps the rest', () {
      final ws = CollectionWorkspaceParser.parse({
        'ActualCollections': [
          row({'ActualId': null}), // no key
          row({'ActualId': 'abc'}),
          row({'ActualId': 5, 'CollectionDate': ''}), // no month
          row({'ActualId': 6, 'CollectionDate': 'Sept 12'}),
          'not a row',
          42,
          row({'ActualId': '8', 'CollectionDate': '2026-09-03T00:00:00'}),
          row({'ActualId': 9, 'Remarks': null, 'ReferenceNo': null}),
        ],
      });
      expect(ws.actualCollections.map((a) => a.actualId), [8, 9]);
      expect(ws.actualCollections.first.collectionDate, '2026-09-03',
          reason: 'a timestamp is cut to its day');
      expect(ws.actualCollections.last.remarks, '');
      expect(ws.actualCollections.last.referenceNo, '');
    });
  });
}
