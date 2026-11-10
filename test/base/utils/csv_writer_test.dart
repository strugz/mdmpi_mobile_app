import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/csv_writer.dart';
import 'package:mdmpi_mobile_app/data/models/report_table.dart';

void main() {
  group('BCsv.cell', () {
    test('plain text is left alone', () => expect(BCsv.cell('Amka'), 'Amka'));

    test('commas, quotes and line breaks are quoted; quotes doubled', () {
      expect(BCsv.cell('a,b'), '"a,b"');
      expect(BCsv.cell('say "hi"'), '"say ""hi"""');
      expect(BCsv.cell('two\nlines'), '"two\nlines"');
    });

    test('text Excel would run as a formula gets an apostrophe', () {
      expect(BCsv.cell('=SUM(A1)'), "'=SUM(A1)");
      expect(BCsv.cell('+63 917'), "'+63 917");
      expect(BCsv.cell('-1'), "'-1");
      expect(BCsv.cell('@x'), "'@x");
    });
  });

  group('BCsv.encode', () {
    const table = ReportTable(
      title: 't',
      headers: ['Client', 'Amount', 'On'],
      rows: [
        [
          ReportCell.text('Amka, Inc.'),
          ReportCell.money(-1234.5),
          ReportCell.date(null),
        ],
      ],
      totals: [
        ReportCell.text('Total'),
        ReportCell.money(1000),
        ReportCell.blank,
      ],
    );

    test('BOM, CRLF, numbers unguarded, totals last', () {
      final csv = BCsv.encode(table);
      expect(csv.startsWith(BCsv.bom), isTrue);
      expect(
          csv.substring(1),
          'Client,Amount,On\r\n'
          '"Amka, Inc.",-1234.50,\r\n'
          'Total,1000.00,\r\n');
    });

    test('without BOM; bytes are UTF-8', () {
      expect(BCsv.encode(table, withBom: false).startsWith('Client'), isTrue);
      final bytes = BCsv.bytes(table);
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM for Excel');
      expect(bytes, utf8.encode(BCsv.encode(table)));
    });

    test('dates as yyyy-MM-dd, money as plain numbers', () {
      expect(ReportCell.date(DateTime(2026, 9, 3)).csv, '2026-09-03');
      expect(const ReportCell.money(1234567.891).csv, '1234567.89');
      expect(const ReportCell.integer(4).csv, '4');
    });
  });

  test('file names drop characters files cannot hold', () {
    expect(
        BReportFileName.build('activity', collector: 'J/C A', period: '2026-09'),
        'mdmpi_activity_J_C_A_2026-09.csv');
    expect(BReportFileName.build('recon'), 'mdmpi_recon.csv');
  });
}
