import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/models/bank_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/widgets/bank_picker_sheet.dart';

/// The bank was free text, so one bank reached the server as "BPI", "bpi" and
/// "Bank of the Philippine Islands" depending on who recorded it. These pin
/// the two things that stop: the shape the company list arrives in, and a
/// picker that finds a bank however the collector thinks of it.

/// Rows exactly as `/api2/DRPMST/banklist` returns them.
const _payload = [
  {
    'mid': '3',
    'bankcode': 'BPI',
    'bank': 'Bank of the Philippine Islands',
    'created_at': '04/22/2024 13:56:24'
  },
  {
    'mid': '14',
    'bankcode': 'MET',
    'bank': 'Metrobank',
    'created_at': '04/22/2024 13:56:24'
  },
  {
    'mid': '1',
    'bankcode': 'BDO',
    'bank': 'Banco de Oro',
    'created_at': '04/22/2024 13:56:24'
  },
];

List<BankModel> get _banks =>
    [for (final row in _payload) BankModel.fromJson(row)];

Future<void> _open(WidgetTester tester,
    {List<BankModel>? banks, String? selected}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: BankPickerSheet(banks: banks ?? _banks, selected: selected),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('the payload', () {
    test('maps the fields the endpoint actually sends', () {
      final bank = BankModel.fromJson(_payload.first);

      expect(bank.id, '3');
      expect(bank.code, 'BPI');
      expect(bank.name, 'Bank of the Philippine Islands');
      // The code is what gets recorded: it is what the company's own records
      // key on, and it fits a field next to a check number.
      expect(bank.label, 'BPI');
    });

    test('survives a row with missing fields', () {
      final bank = BankModel.fromJson(const {'mid': '99'});

      expect(bank.code, '');
      expect(bank.name, '');
      expect(bank.label, '');
    });

    test('falls back to the name when a row carries no code', () {
      final bank =
          BankModel.fromJson(const {'mid': '1', 'bank': 'Banco de Oro'});

      expect(bank.label, 'Banco de Oro');
    });

    test('round-trips through the local cache', () {
      final bank = BankModel.fromJson(_payload.first);
      final restored = BankModel.fromDbMap(bank.toDbMap());

      expect(restored.id, bank.id);
      expect(restored.code, bank.code);
      expect(restored.name, bank.name);
    });
  });

  group('matching', () {
    test('finds a bank by its code or any part of its name', () {
      final bpi = BankModel.fromJson(_payload.first);

      expect(bpi.matches('bpi'), isTrue, reason: 'by code, lowercase');
      expect(bpi.matches('BPI'), isTrue);
      expect(bpi.matches('philippine'), isTrue, reason: 'mid-name');
      expect(bpi.matches('Bank of the'), isTrue);
      expect(bpi.matches('metro'), isFalse);
    });

    test('an empty query matches everything', () {
      expect(_banks.where((b) => b.matches('  ')).length, _banks.length);
    });
  });

  group('what the picker hands back', () {
    testWidgets('the code, not the full name', (tester) async {
      BankModel? chosen;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                chosen = await BankPickerSheet.show(context, banks: _banks);
              },
              child: const Text('pick'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bank of the Philippine Islands'));
      await tester.pumpAndSettle();

      expect(chosen?.label, 'BPI');
    });
  });

  group('legacy values', () {
    test('a full name recorded before the picker resolves to its code', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.banks.assignAll(_banks);

      expect(c.canonicalBankName('Bank of the Philippine Islands'), 'BPI');
      expect(c.canonicalBankName('bank of the philippine islands'), 'BPI');
      expect(c.canonicalBankName('BPI'), 'BPI');
    });

    test('a bank that is not on the company list is kept as recorded', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.banks.assignAll(_banks);

      // Better offered as it was typed than dropped on the floor.
      expect(c.canonicalBankName('Some Rural Bank'), 'Some Rural Bank');
      expect(c.canonicalBankName('   '), '');
    });

    test('the same bank recorded two ways counts as one recent bank', () {
      final c = CollectionActivityController();
      c.startAggregateTracking();
      c.banks.assignAll(_banks);
      c.bucketItems.assignAll([
        CollectionItemModel(
          id: '1',
          client: ClientModel(
              id: 'A',
              code: 'c',
              name: 'A',
              address: '',
              contact: '',
              emailAddress: ''),
          toBeCollected: 100,
          history: const [
            CollectionHistoryModel(
                date: '2026-09-01',
                collectorName: 'Juan',
                status: 'Collected',
                bankName: 'BPI'),
            CollectionHistoryModel(
                date: '2026-09-02',
                collectorName: 'Juan',
                status: 'Collected',
                bankName: 'Bank of the Philippine Islands'),
          ],
        ),
      ]);

      expect(c.recentBankNames(), ['BPI']);
    });
  });

  group('the picker', () {
    testWidgets('lists every bank, with its code', (tester) async {
      await _open(tester);

      expect(find.text('Bank of the Philippine Islands'), findsOneWidget);
      expect(find.text('Metrobank'), findsOneWidget);
      expect(find.text('BDO'), findsOneWidget);
    });

    testWidgets('filters as the collector types', (tester) async {
      await _open(tester);

      await tester.enterText(find.byType(TextField).first, 'metro');
      await tester.pumpAndSettle();

      expect(find.text('Metrobank'), findsOneWidget);
      expect(find.text('Bank of the Philippine Islands'), findsNothing);
    });

    testWidgets('a code the collector says out loud finds the full name',
        (tester) async {
      await _open(tester);

      await tester.enterText(find.byType(TextField).first, 'BPI');
      await tester.pumpAndSettle();

      expect(find.text('Bank of the Philippine Islands'), findsOneWidget);
      expect(find.text('Metrobank'), findsNothing);
    });

    testWidgets('says so when nothing matches', (tester) async {
      await _open(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('No bank matches'), findsOneWidget);
    });

    testWidgets('an undownloaded list sends the collector back to typing',
        (tester) async {
      // The list is cached on the device, so this is only the state before
      // the first successful download — and it must not be a dead end.
      await _open(tester, banks: const []);

      expect(find.textContaining('has not downloaded yet'), findsOneWidget);
    });

    testWidgets('marks whichever bank is already on the form', (tester) async {
      await _open(tester, selected: 'Metrobank');

      final marked = tester.widget<Text>(find.text('Metrobank'));
      expect(marked.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('a value recorded as a bare code still shows as selected',
        (tester) async {
      // Engagements saved before the picker existed hold whatever was typed.
      await _open(tester, selected: 'BDO');

      final marked = tester.widget<Text>(find.text('Banco de Oro'));
      expect(marked.style?.fontWeight, FontWeight.w700);
    });
  });
}
